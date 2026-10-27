# ==========================================
# ETAPA 1: Instalación de Dependencias (Builder)
# ==========================================
# Imagen base inmutable de Composer en versión específica (sin etiqueta :latest)
FROM composer:2.7.2 AS builder

WORKDIR /app

# Optimización de caché y gestión de dependencias reproducibles:
# Copiar primero el manifiesto (composer.json) y el archivo de bloqueo (composer.lock si existe)
COPY composer.json composer.lock* ./

# Instalar dependencias de producción excluyendo las de desarrollo
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress


# ==========================================
# ETAPA 2: Entorno de Ejecución Final (Runner)
# ==========================================
# Imagen base inmutable ligera de PHP CLI basada en Alpine Linux
FROM php:8.2.18-cli-alpine3.19 AS runner

WORKDIR /app

# Principio de Mínimo Privilegio:
# Ajustar permisos del directorio al usuario integrado sin privilegios 'www-data'
RUN chown -R www-data:www-data /app

# Copiar el directorio de dependencias 'vendor' desde la etapa de compilación
COPY --chown=www-data:www-data --from=builder /app/vendor /app/vendor

# Copiar el código fuente y el manifiesto
COPY --chown=www-data:www-data composer.json ./
COPY --chown=www-data:www-data index.php ./

# Cambiar el contexto de ejecución al usuario no-root 'www-data'
USER www-data

# Exponer el puerto configurado
EXPOSE 8080

# Sintaxis de ejecución segura: formato JSON/Array (exec form)
# Levanta el servidor embebido de PHP en el puerto 8080 sirviendo la carpeta /app
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app"]
