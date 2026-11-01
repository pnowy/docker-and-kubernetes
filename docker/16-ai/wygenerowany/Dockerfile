# Dockerfile w stylu typowej odpowiedzi AI na krótki prompt – znajdź błędy według ../checklista.md
FROM node:latest
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
ENV PGPASSWORD=haslo-w-obrazie
EXPOSE 8080
CMD npm start
