# Usar una imagen oficial y ligera de Node.js
FROM node:18-alpine

# Definir el directorio de trabajo dentro del contenedor
WORKDIR /usr/src/app

# Copiar los archivos de dependencias
COPY package*.json ./

# Instalar dependencias del proyecto
RUN npm install

# Copiar el resto del código fuente del proyecto
COPY . .

# Exponer el puerto en el que escucha tu aplicación (ejemplo: 3000)
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["npm", "start"]