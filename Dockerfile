########################
# STAGE 1: Frontend build
########################
FROM node:20-alpine AS frontend

# เตรียม directory และสิทธิ์
RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app
WORKDIR /home/node/app

# ติดตั้ง dependencies ด้วยสิทธิ์ user node
COPY ./frontend/package*.json ./
USER node
RUN npm ci

# คัดลอก source code
COPY --chown=node:node ./frontend/ ./frontend
COPY --chown=node:node ./static/ ./static

# Build frontend
WORKDIR /home/node/app/frontend
RUN NODE_OPTIONS=--max_old_space_size=8192 npm run build

########################
# STAGE 2: Backend + Serve
########################
FROM python:3.11-alpine

# ติดตั้ง dependencies ที่จำเป็นสำหรับ build Python packages
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    libffi-dev \
    openssl-dev \
    curl && \
    apk add --no-cache \
    libpq

# Install Python packages
COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt && \
    rm -rf /root/.cache

# คัดลอก source code และ static files จาก frontend
COPY . /usr/src/app/
COPY --from=frontend /home/node/app/static /usr/src/app/static/

# ตั้ง working dir
WORKDIR /usr/src/app
EXPOSE 80

# เริ่มรันแอป (เหมาะสำหรับ Flask/FastAPI)
CMD ["gunicorn", "-b", "0.0.0.0:80", "app:app"]
