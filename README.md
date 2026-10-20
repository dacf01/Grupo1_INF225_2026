# Grupo 1

Este es el repositorio del *Grupo 1*, cuyos integrantes son:

* Bejamín Solís - 202430511-5
* Ángel Peña - 202430503-4
* Martin Cumbaynar - 202330503-0
* Pablo Gajardo - 201804582-9
* Diego Cisterna - 202023511-2
* Sebastián Césped - 202273603-8

* **Ayudante**: Josefina Pino


## Setup proyecto
Para este proyecto se ocupa:
- Docker y Docker Compose
- (Opcional, si se ejecuta local sin Docker) Node.js (v22.16.0) y PostgreSQL (v14 o superior)

Importante: la forma recomendada de levantar el proyecto es con Docker Compose. En esta configuración, PostgreSQL también corre dentro de Docker.

### 1) Configurar variables de entorno para Docker
Docker Compose usa el archivo `.env.docker`. El repositorio ya incluye valores de desarrollo para levantar la base de datos, backend y frontend.

Si necesitas cambiar credenciales o nombre de la base de datos, modifica `.env.docker` y luego recrea los contenedores.

## 2) Configuración de la Base de Datos
Para este proyecto, se utiliza **PostgreSQL** dentro de Docker.

### 2.1) Inicialización automática
Al ejecutar Docker Compose, se crea el contenedor de PostgreSQL y el backend ejecuta automáticamente la migración con `esquema.sql`.

```bash
docker compose up --build
```

Servicios disponibles:
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8000`
- PostgreSQL: `localhost:5432`

Para conectarse a PostgreSQL dentro del contenedor:

```bash
docker compose exec db psql -U usuario -d practica
```
Contraseña: `password`

También se expone en `localhost:5432`, pero si tienes PostgreSQL instalado localmente puede haber conflictos. En ese caso, usa el comando con `docker compose exec`.

Si hay problemas de credenciales por datos antiguos en Docker, reinicia eliminando el volumen de la base de datos:

```bash
docker compose down -v
docker compose up --build
```

Advertencia: `docker compose down -v` borra los datos guardados en la base de datos Docker.


## Aspectos técnicos relevantes

Adjuntamos a continuación algunas credenciales de acceso para hacer pruebas:

- Estudiante:
```bash
mail: rpenax@usm.cl
password: 1234
```
- Empresa:
```bash
mail: rrhh@felicity.cl || empleos@iaspa.cl
password: 1234 (ambas)
```
- Encargado de práctica:
```bash
mail: coordinador.practicas@usm.cl
password: 1234
```

 
