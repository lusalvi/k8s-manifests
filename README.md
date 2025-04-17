# Cátedra Computación en la Nube - Instituto Tecnológico Universitario (UNCUYO)
## 0311AT – K8S: Casi como en producción

### 🎯 Objetivo

Esta primer actividad de taller tiene el objetivo de poner a prueba el nivel de autonomía de los alumnos y
de conocimientos adquiridos hasta el momento no solo en la materia, sino integrando conocimientos de otros
espacios curriculares de la carrera exponiéndolos a un escenario laborar real en el cual podrán y deberán aplicar
los conocimientos adquirido hasta el momento. Para esto deberá demostrar autonomía técnica al resolver un
despliegue funcional sin instrucciones paso a paso.

Esta es una actividad individual, y el objetivo de la misma es que debe ser llevada a cabo sin asistencia
directa, pudiendo consultar documentación, foros o herramientas como ChatGPT, pero todo debe estar
entendido, aplicado y documentado por cada alumno, con el objeto de identificar falencias y oportunidades de
mejora.

---
### 📝 Contexto

Te sumás como ingeniero DevOps Jr. a un equipo de desarrollo de una pequeña empresa que necesita
desplegar un entorno de trabajo para que el equipo de desarrollo pueda trabajar con la versión de contenido
estático de su página web institucional. Como parte de tu primer trabajo, deberás confeccionar un entorno de
trabajo en forma local en Minikube, con manifiestos de despliegue de aplicaciones, almacenamiento persistente y
uso de Git y GitHub, y documentar todo el proceso con el objeto de pasarle dicha documentación al resto del
equipo de desarrolladores de la empresa para que puedan trabajar en dicho entorno.

Se debe de tener en cuenta que la aplicación debe poder servirse por navegador en forma local, con
contenido propio (no el default de la plantilla), el cual estará alojado en un volumen persistente que se mantenga
incluso si la aplicación se reinicia, pero que la misma debe estar vinculada al repositorio de git de su cuenta de
Github.

---
### ❗ Consignas

A partir del contexto planteado, deberás crear dos directorios locales:
- Un directorio para el contenido de la pagina web
- Un directorio para el contenido de los manifiestos de kuberentes
  
Cada uno sera un repositorio git, los cuales estarán vinculares dos repositorios publicos ubicados en tu cuenta
de Github

---

### 🚀 Paso a paso para reproducir el entorno completo

#### 🛠️ 1. Crear el clúster de Minikube

```bash
minikube start --driver=docker
```

Verificá que el clúster esté activo:

```bash
kubectl get nodes
```

---

#### 📂 2. Preparar carpetas locales

```bash
mkdir 0311_Cloud
cd 0311_Cloud
mkdir k8s-manifests
cd k8s-manifests
mkdir deployments,services,volumes
```

---

#### 🧬 3. Clonar repositorio de sitio web

##### Clonar contenido del sitio web

Volver a la carpeta `0311_Cloud` con `cd`, hacer fork del repositorio base `https://github.com/ewojjowe/static-website`, clonarlo e inicializarlo:

```bash
cd ..
git clone https://github.com/TU_USUARIO/static-website.git
git init
```

Hacer los cambios necesarios y realizar los commits.

#### ⚙️ 4. Crear manifiestos de Kubernete

##### Volúmenes Persistentes

1. Moverse a la carpeta de `volumes` y crear `pv.yaml`:
```bash
cd k8s-manifests/volumes
New-Item -Path . -Name "pv.yaml" -ItemType "File"
```
El archivo se creará vacío, pero lo completaremos con esto:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-web-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  hostPath:
    path: /mnt/web/static-website
```

   
2. Crear `pvc.yaml`:
```bash
New-Item -Path . -Name "pvc.yaml" -ItemType "File"
```
El archivo se creará vacío, pero lo completaremos con esto:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-web-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 1Gi
```

3. Aplicar cambios para crear los archivos correctamente. Verificar que todo esté ejecutándose correctamente:
```bash
kubectl apply -f .
kubectl get pv,pvc
```

##### Deployment
1. Moverse a la carpeta de `deployments` y crear archivo yaml:
```bash
cd ../deployments
kubectl create deployment static-website-deployment --image=nginx --dry-run=client -o yaml > deployment.yaml
```

2. Editar `deployments.yaml` para agregarle el puerto y el volumen. Debería quedar algo así:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: static-website-deployment
  name: static-website-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: static-website-deployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: static-website-deployment
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: static-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: static-content
        persistentVolumeClaim:
          claimName: static-web-pvc
```

3. Aplicar cambios y verificar que se esté ejecutando correctamente:
```bash
kubectl apply -f .
kubectl get deployments
```
##### Service
1. Moverse a la carpeta de `services`, crear archivo yaml y verificar que se esté ejecutando correctamente:
```bash
cd ../services
kubectl expose deployment static-website-deployment --port=80 --target-port=80 --type=NodePort --dry-run=client -o yaml > service.yaml
kubectl apply -f .
kubectl get services
```

#### ✍🏼 5. Crear repositorio de manifiestos en GitHub
1. Crear desde GitHub un repositorio nuevo llamado `k8s-manifests`.
2. Desde la terminal, parados sobre la carpeta `k8s-manifests`, inicializarla y enviar el repositorio existente:
```bash
cd ..
git init
git remote add origin https://github.com/TU_USUARIO/k8s-manifests.git
git status
```

3. Hacer los commits correspondientes para subir los archivos creados anteriormente a GitHub.

#### 🌐 6. Despliegue de la página
1. Borrar el clúster creado, volver a montarlo correctamente a la carpeta que usó en el hostPath al crear los volúmenes persistentes y volver a crear los archivos:
```bash
minikube delete
minikube start --driver=docker --mount --mount-string="C:/Users/HP/0311_Cloud/static-website:/mnt/web/static-website"
kubectl apply -f volumes/.
kubectl apply -f deployments/.
kubectl apply -f services/.
```

2. Verificar que todo se esté ejecutando correctamente:
```bash
kubectl get pods
kubectl get deployments
```

3. Exponer el servicio:
```bash
minikube service static-website-deployment
```

---

### Resultado esperado
- ✅ El pod se encuentra en estado Running (`kubectl get pods`)
- ✅ El servicio está activo y expone un NodePort (`kubectl get services`)
- ✅ El sitio se visualiza correctamente desde el navegador al ejecutar `minikube service ...`
