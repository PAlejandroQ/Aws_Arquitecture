#!/bin/bash
# Script de inicialización para el laboratorio RAG en EC2 Ubuntu
# Este script se ejecuta automáticamente al iniciar la instancia EC2

# 1. Actualizar el sistema e instalar dependencias básicas
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y python3 python3-pip git

# 2. Instalar el gestor de paquetes de Python (pip ya viene con python3-pip)
sudo pip3 install --upgrade pip

# 3. Clonar el proyecto RAG de demostración
# NOTA: Reemplaza con la URL de tu repositorio real de GitHub
git clone https://github.com/tu_usuario/tu_proyecto_rag.git /home/ubuntu/rag-demo
chown -R ubuntu:ubuntu /home/ubuntu/rag-demo
cd /home/ubuntu/rag-demo

# 4. Instalar librerías de Python desde requirements.txt
sudo pip3 install -r requirements.txt

# 5. Ejecutar la API en segundo plano
# Para el laboratorio usamos un servidor de desarrollo simple
# En producción se usaría Gunicorn/Uvicorn con nginx
nohup python3 app.py &

# El script termina aquí, pero la API sigue ejecutándose en segundo plano
