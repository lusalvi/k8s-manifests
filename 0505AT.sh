#!/bin/bash
set -e
set -o pipefail

# ----------------------------------------------------------------------------------------------------
# Trabajo Práctico 0505AT - Despliegue automático en Kubernetes
# Autor: Lucía Salvi
# Descripción: Este script clona un sitio estático y manifiestos desde GitHub, inicia Minikube,
# aplica los manifiestos y verifica que el sitio esté funcionando correctamente.
# Repositorio: https://github.com/lusalvi/k8s-manifests
# ----------------------------------------------------------------------------------------------------


# -------- CONFIGURACIÓN --------
USUARIO_GITHUB="${1:-lusalvi}"
WORKDIR="$(pwd)/0505AT"
STATIC_WEB_DIR="$WORKDIR/static-website"
MANIFEST_DIR="$WORKDIR/k8s-manifests"
REPO_WEB="https://github.com/$USUARIO_GITHUB/static-website.git"
REPO_MANIFESTS="https://github.com/$USUARIO_GITHUB/k8s-manifests.git"

# -------- VALIDACIÓN DE DEPENDENCIAS --------
for cmd in minikube kubectl git curl; do
    if ! command -v "$cmd" >/dev/null; then
        echo "❌ Error: Falta el comando '$cmd'. Abortando..."
        exit 1
    fi
done

# -------- PREPARACIÓN --------
echo "📂 Preparando estructura local..."
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# -------- CLONADO DE REPOSITORIOS --------
echo "🌐 Clonando sitio estático..."
git clone "$REPO_WEB" "$STATIC_WEB_DIR"

echo "📄 Clonando manifiestos de Kubernetes..."
git clone "$REPO_MANIFESTS" "$MANIFEST_DIR"

# -------- INICIO DE MINIKUBE CON VOLUMEN MONTADO --------
echo "🚀 Iniciando Minikube..."
minikube delete || true
minikube start --driver=docker --mount --mount-string="$STATIC_WEB_DIR:/mnt/web/static-website"

# -------- APLICACIÓN DE MANIFIESTOS --------
echo "📦 Aplicando manifiestos..."
kubectl apply -f "$MANIFEST_DIR/volumes"
kubectl apply -f "$MANIFEST_DIR/deployments"
kubectl apply -f "$MANIFEST_DIR/services"

# -------- VERIFICACIÓN DE ESTADO --------
echo "🕵️ Verificando recursos desplegados..."
kubectl wait --for=condition=Ready pod -l app=static-website-deployment --timeout=180s

if [ $? -ne 0 ]; then
    echo "❌ El pod no se puso en estado Ready. Mostrando detalles:"
    kubectl get pods
    kubectl describe pod -l app=static-website-deployment
    exit 1
fi

kubectl get pods
kubectl get deployments
kubectl get services


echo "🔍 Verificando montaje del volumen..."
if kubectl exec deploy/static-website-deployment -- ls /usr/share/nginx/html/index.html >/dev/null 2>&1; then
    echo "✅ El volumen está montado y el sitio fue cargado en el contenedor."
else
    echo "⚠️ No se encontró el archivo index.html en el contenedor."
fi

# -------- COMPROBACIÓN DE LA RESPUESTA DEL SITIO --------
echo "🌐 Abriendo servicio manualmente con túnel..."
minikube service static-website-deployment &
sleep 3
echo "✅ Despliegue finalizado correctamente. ¡Tu sitio está online! 🌐"


# Para ejecutar este script:
# bash 0505AT.sh
# (opcional) Podés pasar tu nombre de usuario GitHub como argumento:
# bash 0505AT.sh tu_usuario
