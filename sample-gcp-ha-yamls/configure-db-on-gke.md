To access a Cloud SQL instance from an application running in Google Kubernetes Engine, 
you can use either the Cloud SQL Auth Proxy (with public or private IP),
 or connect directly using a private IP address.
 
 https://cloud.google.com/sql/docs/mysql/connect-kubernetes-engine


To set up a PostgreSQL database that can be used from a GKE cluster, follow these steps:

#### 1. Create a PostgreSQL Instance on Google Cloud SQL

1. **Create a Cloud SQL instance**:
   ```sh
   gcloud sql instances create gke1-postgres-instance \
       --database-version=POSTGRES_14 \
       --cpu=2 \
       --memory=16384MB \
       --region=us-central1
   ```

2. **Create a database**:
   ```sh
   gcloud sql databases create nexus --instance=gke1-postgres-instance
   ```

3. **Create a user**:
   ```sh
   gcloud sql users create nxrm --instance=gke1-postgres-instance --password=nxrm
   ```

#### 2. Configure Network Access


Here are the steps to set up VPC peering:

1. **Enable the Service Networking API**:

    ```sh
    gcloud services enable servicenetworking.googleapis.com
    ```

    Create a VPC peering connection: 

   ```sh
   gcloud compute addresses create google-managed-services-default \
           --global \
            --purpose=VPC_PEERING \
            --prefix-length=16 \
            --network=default \
            --description="Peering range for gke1" \
            --addresses=10.10.0.0
   ```
2. Create the VPC peering:  
   ```sh
   gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --network=default \
    --ranges=google-managed-services-default
   ```
3. **Patch the Cloud SQL instance**:
   After setting up the VPC peering, you can patch your Cloud SQL instance to use the private IP.

   ```sh
   gcloud sql instances patch gke1-postgres-instance \
       --network=default \
       --no-assign-ip
   ```

    How to get IP range for GKE cluster:
   ```sh
   gcloud container clusters describe test-gke-cluster --zone us-central1-1 --format="get(clusterIpv4Cidr)"
   ````
   
4. **Authorize the GKE cluster to access the Cloud SQL instance**:
   ```sh
   gcloud sql instances patch gke1-postgres-instance --authorized-networks=<GKE_CLUSTER_IP_RANGE>
   ```


Now you can use the private IP address of the Cloud SQL instance to connect from the GKE cluster directly
[Connect to Cloud SQL without the Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/mysql/connect-kubernetes-engine#private-ip)
 or use the Cloud SQL Proxy [Connect to Cloud SQL using the Cloud SQL Auth Proxy]https://cloud.google.com/sql/docs/mysql/connect-kubernetes-engine#proxy.


#### How to deploy the Cloud SQL Proxy in GKE

1. **Create a Kubernetes secret for the Cloud SQL credentials**:
   ```sh
   kubectl create secret generic cloudsql-instance-credentials \
       --from-file=credentials.json=<PATH_TO_SERVICE_ACCOUNT_KEY>
   ```

2. **Deploy the Cloud SQL Proxy as a sidecar container**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: myapp-deployment
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: myapp
     template:
       metadata:
         labels:
           app: myapp
       spec:
         containers:
         - name: myapp
           image: gcr.io/my-project/myapp:latest
           env:
           - name: DB_HOST
             value: 127.0.0.1
           - name: DB_PORT
             value: "5432"
           - name: DB_NAME
             value: mydatabase
           - name: DB_USER
             value: myuser
           - name: DB_PASSWORD
             valueFrom:
               secretKeyRef:
                 name: cloudsql-instance-credentials
                 key: password
           ports:
           - containerPort: 8080
         - name: cloudsql-proxy
           image: gcr.io/cloudsql-docker/gce-proxy:1.19.1
           command: ["/cloud_sql_proxy",
                     "-instances=my-project:us-central1:my-postgres-instance=tcp:5432",
                     "-credential_file=/secrets/cloudsql/credentials.json"]
           volumeMounts:
           - name: cloudsql-instance-credentials
             mountPath: /secrets/cloudsql
             readOnly: true
         volumes:
         - name: cloudsql-instance-credentials
           secret:
             secretName: cloudsql-instance-credentials
   ```

### 4. Update Application Configuration

Ensure your application is configured to use the environment variables for database connection.
