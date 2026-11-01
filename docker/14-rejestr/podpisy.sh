#!/usr/bin/env bash
# Sekcja 14 – Podpisywanie i weryfikacja obrazów: cosign z własną parą kluczy, lokalny rejestr
# cosign to narzędzie Sigstore, nie część Dockera: brew install cosign / https://docs.sigstore.dev/cosign/system_config/installation/
# Bez instalacji – cosign w kontenerze (--network host: localhost:5000 to rejestr z rejestr.sh)
cd "$(mktemp -d)" || exit 1
cosign() { docker run --rm -v "$PWD":/w -w /w --network host -e COSIGN_PASSWORD ghcr.io/sigstore/cosign/cosign:v3.1.4 "$@"; }
export COSIGN_PASSWORD=szkolenie   # hasło do klucza prywatnego (w CI: sekret)

# Rejestr i obraz z rejestr.sh
docker start registry 2>/dev/null || docker run -d -p 5000:5000 --name registry -v registry-data:/var/lib/registry registry:2
docker tag notes-api:1.0.0 localhost:5000/notes-api:1.0.0
docker push -q localhost:5000/notes-api:1.0.0

# 1. Para kluczy: cosign.key (prywatny, zaszyfrowany hasłem) i cosign.pub (publiczny – dla weryfikujących)
cosign generate-key-pair
ls -l cosign.*

# 2. Podpisujemy digest, nie tag – tag jest ruchomy
DIGEST=$(docker buildx imagetools inspect localhost:5000/notes-api:1.0.0 --format '{{.Manifest.Digest}}')
echo "$DIGEST"
# laboratorium: bez publicznego logu przejrzystości Rekor i po HTTP
cosign sign --yes --key cosign.key --allow-http-registry --use-signing-config=false --tlog-upload=false \
  "localhost:5000/notes-api@$DIGEST"

# 3. Podpis leży w rejestrze obok obrazu (artefakt OCI powiązany przez referrers API)
cosign tree --allow-http-registry localhost:5000/notes-api:1.0.0

# 4. Weryfikacja kluczem publicznym – sukces
cosign verify --key cosign.pub --allow-http-registry --insecure-ignore-tlog=true localhost:5000/notes-api:1.0.0

# 5. Ktoś podmienia obraz pod tym samym tagiem – weryfikacja kończy się błędem "no signatures found"
docker tag busybox localhost:5000/notes-api:1.0.0
docker push -q localhost:5000/notes-api:1.0.0
cosign verify --key cosign.pub --allow-http-registry --insecure-ignore-tlog=true localhost:5000/notes-api:1.0.0 \
  || echo "✗ weryfikacja nieudana – nie uruchamiamy tego obrazu"

# Przywrócenie właściwego obrazu
docker tag notes-api:1.0.0 localhost:5000/notes-api:1.0.0
docker push -q localhost:5000/notes-api:1.0.0

# Produkcyjnie: keyless – tożsamość z OIDC (GitHub Actions, Google, …), certyfikat z Fulcio, wpis w Rekor:
#   cosign sign --yes ghcr.io/<org>/notes-api@sha256:…           # w CI – patrz ci/docker.yml
#   cosign verify ghcr.io/<org>/notes-api:1.0.0 \
#     --certificate-identity-regexp 'https://github.com/<org>/notes-api/.*' \
#     --certificate-oidc-issuer https://token.actions.githubusercontent.com
# Wymuszanie podpisów w klastrze: Kyverno lub Sigstore policy-controller (część Kubernetes).
# Docker Content Trust (DOCKER_CONTENT_TRUST=1, Notary v1) – rozwiązanie historyczne, wycofywane.
