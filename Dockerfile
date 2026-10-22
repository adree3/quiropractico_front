# ==========================================
# Etapa 1: Compilación de Flutter Web
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Descargar dependencias primero para aprovechar la caché de Docker
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el código fuente
COPY . .

# Argumento para inyectar la URL de la API (por defecto producción)
ARG API_URL=https://medicoxos-api.adrianaloper.es/api

# Compilar Flutter Web en release
RUN flutter build web --release --dart-define=API_URL=$API_URL

# ==========================================
# Etapa 2: Servidor Web Nginx ligero (~25MB)
# ==========================================
FROM nginx:alpine

# Copiar bundle compilado al directorio raíz de Nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copiar configuración con soporte SPA y compresión gzip
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
