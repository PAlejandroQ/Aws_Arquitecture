Esta es una excelente estrategia. Utilizar AWS CLI no solo es más preciso y detallado para una exposición técnica, sino que también establece la base para la automatización. La restricción de costos es crítica, por lo que nos enfocaremos en recursos elegibles para la **Capa Gratuita (Free Tier)** de AWS para el laboratorio.

A continuación, presento la estructura de la exposición/laboratorio, diferenciando el **Caso Lab (Bajo Costo)** del **Caso Real (Producción)**.

---

## Estructura de la Exposición/Laboratorio: Despliegue RAG con AWS CLI y CloudFormation

### I. Introducción y Fundamentos (5 min)

| Tema | Puntos Clave a Detallar |
| :--- | :--- |
| **A. RAG y el Problema del Despliegue** | 1. **Motivación:** Por qué RAG (datos privados, actualidad, citación). 2. **Componentes:** *Retriever* (Base de Vectores) y *Generator* (LLM/API). |
| **B. AWS EC2: La Plataforma** | 1. **Definición:** Cómputo escalable y control total. 2. **Modelo de Precios:** Introducir *Free Tier* como mecanismo para el Lab. |
| **C. AWS CLI y CloudFormation** | 1. **CLI:** Interacción programática y detallada (Ideal para Lab). 2. **CloudFormation (IaC):** Automatización, consistencia y gestión de costos a largo plazo (el objetivo final). |

---

### II. Laboratorio 1: Configuración Paso a Paso con AWS CLI (20-25 min)

En esta fase, crearemos los componentes de infraestructura en el orden correcto, utilizando **recursos Free Tier** (ej. `t2.micro`, Amazon Linux, 8 GB de EBS) para cumplir con la restricción de $50.

#### **1. Seguridad y Acceso (El requisito SSH)**

| Concepto AWS | Comando AWS CLI (Lab Case) | Detalle y Explicación |
| :--- | :--- | :--- |
| **Par de Claves (Key Pair)** | `aws ec2 create-key-pair --key-name RAG-Key-Lab --query 'KeyMaterial' --output text > RAG-Key-Lab.pem` | **Detalle:** La llave privada (`.pem`) es la única forma de autenticarse via SSH. |
| **Grupo de Seguridad (SG)** | 1. `aws ec2 create-security-group --group-name RAG-SG --description "Allow SSH and API"` | **Detalle:** Actúa como un firewall virtual. Necesitamos abrir puertos. |
| **Reglas de Entrada (Ingress)** | 2. `aws ec2 authorize-security-group-ingress --group-name RAG-SG --protocol tcp --port 22 --cidr 0.0.0.0/0` (Para demo) / **Real:** `192.168.1.1/32` (solo tu IP) | **Detalle:** Abrir **Puerto 22 (SSH)**. **Caso Real:** Limitar a IPs específicas. |
| **Regla para la API** | 3. `aws ec2 authorize-security-group-ingress --group-name RAG-SG --protocol tcp --port 8000 --cidr 0.0.0.0/0` | **Detalle:** Abrir el puerto donde se expondrá el servidor FastAPI/Flask del RAG (ej. 8000). |

#### **2. Creación y Configuración de la EC2**

| Concepto AWS | Comando AWS CLI (Lab Case) | Detalle y Explicación |
| :--- | :--- | :--- |
| **Obtener AMI** | `aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text` | **Detalle:** Necesitas el ID de la AMI (Amazon Machine Image). Usamos Amazon Linux 2 (o 2023) por ser ligero y apto para Free Tier. |
| **Script de Inicialización**| **(User Data)** – Contiene comandos de *bootstrap* que ejecutan: `sudo yum update -y`, `sudo yum install python3 -y`, `git clone <repo_rag>`, `pip install -r requirements.txt`, `nohup python3 api.py &` | **Detalle:** El *User Data* es crucial para la automatización. Instala Python, clona el proyecto RAG (que usa una Base de Vectores *in-memory* como FAISS) y lo inicia como servicio en segundo plano. |
| **Lanzar Instancia** | `aws ec2 run-instances --image-id <AMI_ID> --count 1 --instance-type t2.micro --key-name RAG-Key-Lab --security-group-ids <SG_ID> --user-data file://./setup-rag.sh` | **Detalle:** Se lanza la instancia Free Tier (`t2.micro`), vinculando la llave de acceso y el Grupo de Seguridad. **Caso Real:** Se usaría un tipo de instancia **G-family** (ej. `g5.xlarge`) con GPU para modelos grandes. |

#### **3. Conexión y Verificación**

| Concepto AWS | Comando AWS CLI | Detalle y Explicación |
| :--- | :--- | :--- |
| **Obtener IP Pública** | `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].PublicIpAddress' --output text` | **Detalle:** Necesitamos la IP para la conexión y para probar la API. |
| **Conexión SSH** | `ssh -i RAG-Key-Lab.pem ec2-user@<IP_PUBLICA>` | **Detalle:** Conectarse para verificar logs o realizar ajustes finales. |
| **Prueba de API** | `curl -X POST http://<IP_PUBLICA>:8000/api/rag -H "Content-Type: application/json" -d '{"prompt": "¿Qué es AWS EC2?"}'` | **Detalle:** Verificar que la API de RAG está respondiendo correctamente desde fuera de la instancia. |

---

### III. CloudFormation: La Automatización (10-15 min)

El objetivo final es pasar de la ejecución manual de múltiples comandos CLI a un solo archivo de **Infraestructura como Código (IaC)**.

1.  **Motivación de CloudFormation (CFN):**
    * **Punto Clave:** El CLI crea recursos individuales. CFN crea **Stacks** (pilas), gestionando todos los recursos como una unidad (creación, actualización y eliminación). Es clave para la reproducibilidad.
2.  **Estructura de la Plantilla YAML (Template):**
    * Explicar la división: `Parameters` (entrada del usuario), `Resources` (los componentes AWS), y `Outputs` (datos importantes).
3.  **Mapeo de Recursos (Ejemplo):**
    * Mostrar cómo los comandos CLI se traducen en recursos CFN:
        * El comando `aws ec2 create-key-pair...` se convierte en un recurso `AWS::EC2::KeyPair`.
        * El `Security Group` se convierte en `AWS::EC2::SecurityGroup`.
        * El `run-instances` se convierte en `AWS::EC2::Instance`, y el *User Data* se inserta directamente en la propiedad `UserData`.
4.  **Despliegue con CLI:**
    * **Punto Clave:** Mostrar el comando final que condensa todo el proceso.
    * `aws cloudformation deploy --template-file rag-stack.yaml --stack-name RAG-Lab-Deployment`
5.  **Limpieza:**
    * Enfatizar la facilidad para la gestión de costos: `aws cloudformation delete-stack --stack-name RAG-Lab-Deployment`.

---

### IV. Discusión: Del Lab al Caso Real (5 min)

Este es el momento de verbalizar los cambios que se harían en un proyecto de producción, justificando por qué el *Lab Case* es limitado.

| Componente | Caso Lab (Bajo Costo/t2.micro) | Caso Real (Producción) |
| :--- | :--- | :--- |
| **Cómputo (EC2)** | Instancia `t2.micro` (CPU). | Instancia **G-Family** (GPU, ej. `g5.xlarge`) o **P-Family** para modelos *on-premises*. |
| **Modelo de IA (LLM)** | Modelo pequeño Open Source (Llama 3 8B) ejecutado con Ollama en CPU, o API externa gratuita (con riesgo de cuotas). | **Amazon Bedrock API** (Modelos Claude, Llama 3) o **Amazon SageMaker Endpoint** para modelos propios o *fine-tuned*. |
| **Base de Vectores** | Base de datos local/en memoria (FAISS, ChromaDB local). | **Amazon OpenSearch Serverless** o **Aurora RDS con pgvector** para escalabilidad y persistencia. |
| **Exposición API** | FastAPI/Flask ejecutado directamente en EC2 con `nohup`. | **Application Load Balancer (ALB)** + **Auto Scaling Group** para manejar alto tráfico y *health checks*. |
| **Contenedorización** | No se utiliza. | **Docker** y **Amazon ECS/EKS** para mejor portabilidad y gestión del *deployment*. |

**En resumen:** En el laboratorio probamos la **funcionalidad (Proof of Concept)** con EC2/CLI. En el **Caso Real**, reemplazamos los componentes locales por **servicios gestionados** (Bedrock, OpenSearch, ALB) para garantizar **rendimiento, escalabilidad y alta disponibilidad**.