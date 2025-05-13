# Guía Completa para la Implementación de un Clúster EKS con ArgoCD y Despliegue de Aplicaciones

## **1. Preparación del Entorno**

### **Herramientas Necesarias**

Antes de comenzar, asegúrese de tener instaladas las siguientes herramientas en su máquina:

1. **AWS CLI**: Para interactuar con los servicios de AWS.
2. **Terraform**: Para crear y gestionar la infraestructura en AWS.
3. **Kubectl**: Para administrar el clúster Kubernetes.
4. **Docker Desktop**: Para construir y gestionar imágenes Docker.
5. **Git**: Para clonar el repositorio del proyecto.

### **Esquema de Carpetas del Proyecto Clonado**

Al clonar el repositorio del proyecto, obtendrá las siguientes carpetas principales:

- **kubernetes/**: Contiene los manifiestos YAML necesarios para el despliegue de recursos en Kubernetes.
- **terraform/**: Incluye la configuración de Terraform para la creación del clúster EKS y los nodos.
- **flask-api/**: Contiene la aplicación API que se desplegará. Incluye un `Dockerfile` para crear la imagen de Docker.

Estructura de carpetas:
```
ENTRENAMIENTO_EKS/
├── flask-api/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
├── terraform/
│   ├── main.tf
│   ├── terraform.tfstate
├── README.MD
```

---

## **2. Configuración y Despliegue del Clúster con Terraform**

### **Paso 1: Inicializar Terraform**

1. Entre en la carpeta `terraform` del proyecto:
   ```bash
   cd terraform
   ```

2. Inicialice Terraform:
   ```bash
   terraform init
   ```

3. Planifique la infraestructura:
   ```bash
   terraform plan
   ```

4. Aplique la configuración para desplegar el clúster EKS:
   ```bash
   terraform apply -auto-approve
   ```

   **Nota**: Este proceso puede tardar entre 10 y 15 minutos. Se recomienda usar instancias grandes como `t3.large` o superiores para evitar problemas de capacidad.

---

## **3. Autenticación en Kubernetes**

Después de que Terraform haya creado el clúster, debe autenticarse para interactuar con él:

1. Ejecute el siguiente comando para configurar `kubectl`:
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name test-eks-cluster
   ```

2. Verifique que los nodos del clúster estén activos:
   ```bash
   kubectl get nodes
   ```

---

## **4. Creación y Despliegue de la Imagen Docker**

### **Paso 1: Construir la Imagen Docker**

1. Cambie a la carpeta `flask-api`:
   ```bash
   cd ./flask-api
   ```

2. Construya la imagen Docker, verifica que tengas el docker encendido:
   ```bash
   docker build -t flask-api:latest .
   ```

### **Paso 2: Etiquetar y Subir la Imagen a ECR**

1. Obtenga el URI del repositorio ECR:
   ```bash
   aws ecr describe-repositories --region us-west-2
   ```

3. Etiquete la imagen:
   ```bash
   docker tag flask-api:latest 726181941323.dkr.ecr.us-west-2.amazonaws.com/test-api-repo:latest
   ```

4. Autentíquese en ECR:
   ```bash
   docker login -u AWS -p $(aws ecr get-login-password --region us-west-2) 7xxxxxx.dkr.ecr.us-west-2.amazonaws.com

   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 726181941323.dkr.ecr.us-west-2.amazonaws.com/test-api-repo
   ```

5. Suba la imagen al repositorio ECR:
   ```bash
   docker push 726181941323.dkr.ecr.us-west-2.amazonaws.com/test-api-repo:latest
   
   ```

---

## **5. Instalación de ArgoCD**

### **Paso 1: Desplegar ArgoCD**

1. Aplique el manifiesto de instalación de ArgoCD:
   ```bash
   kubectl delete namespace argocd -> solo si necesitas reinstalar

   cd ./kubernetes  
   kubectl create namespace argocd

   Por defecto: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
  personalizado: kubectl apply -f kubernetes/argocd-service.yaml
   
   
   ```

2. Verifique el estado de los pods:
   ```bash
   kubectl get pods -n argocd
   ```

3. Si los pods no inician, valide los eventos:
   ```bash
   kubectl get events -n argocd

   kubectl get svc -n argocd

   ```

### **Paso 2: Conectarse a ArgoCD**

1. Reenvíe el puerto del servicio `argocd-server`:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443

   ```
añadir loadbalancer
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

```

2. Acceda a ArgoCD en su navegador en `https://localhost:8080`.

3. Obtenga la contraseña predeterminada para el usuario `admin`:
   ```bash
   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```

---

## **6. Despliegue de Aplicaciones en ArgoCD**

### **Paso 1: Añadir el Repositorio**

1. Añada el repositorio de la aplicación en ArgoCD:
   ```bash

1. Recupera el password inicial de ArgoCD
bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
2. Haz login correctamente
argocd login 127.0.0.1:8080 --username admin --password <lo_que_sacaste_arriba> --insecure
3. Ahora sí puedes usar ArgoCD CLI
argocd repo add https://github.com/miguelsancor/entrenamientoEKS.git --insecure

   ```

4. Cree una nueva aplicación:
   ```bash
   argocd app create flask-api-app \
     --repo https://github.com/miguelsancor/entrenamientoEKS.git \
     --path kubernetes \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace default
   ```

5. Sincronice la aplicación:
   ```bash
   argocd app sync flask-api-app
   ```

### **Paso 2: Validar el Despliegue**

1. Verifique que los pods estén corriendo:
   ```bash
   kubectl get pods
   ```

2. Verifique el balanceador de cargas asociado:
   ```bash
   kubectl get svc
   ```

3. Acceda a la API desde la dirección IP o DNS del balanceador de cargas.

---

## **7. Comandos de Monitoreo y Gestión**

- **Ver los nodos y su capacidad:**
  ```bash
  kubectl describe nodes
  kubectl describe pod <NOMBRE_DEL_POD>
  ```

- **Ver los pods en un nodo específico:**
  ```bash
  kubectl get pods --all-namespaces -o wide | grep <NOMBRE_DEL_NODO>
  ```

- **Eliminar pods para redistribuir carga:**
  ```bash
  kubectl delete pod <NOMBRE_DEL_POD>
  ```

---

Habilitar la Sincronización Automática
argocd app set flask-api-app --sync-policy automated

o directamente desde el manifiesto:

prune: true: Elimina automáticamente los recursos que ya no están en el repositorio.
selfHeal: true: Corrige automáticamente cualquier desincronización detectada en los recursos.


Con esta guía detallada, podrá implementar un clúster EKS con ArgoCD, desplegar aplicaciones y manejar problemas comunes. ¡Buena suerte en su clase!
