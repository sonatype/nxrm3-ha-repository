<!--

    Sonatype Nexus (TM) Open Source Version
    Copyright (c) 2008-present Sonatype, Inc.
    All rights reserved. Includes the third-party code listed at http://links.sonatype.com/products/nexus/oss/attributions.

    This program and the accompanying materials are made available under the terms of the Eclipse Public License Version 1.0,
    which accompanies this distribution and is available at http://www.eclipse.org/legal/epl-v10.html.

    Sonatype Nexus (TM) Professional Version is available from Sonatype, Inc. "Sonatype" and "Sonatype Nexus" are trademarks
    of Sonatype, Inc. Apache Maven is a trademark of the Apache Software Foundation. M2eclipse is a trademark of the
    Eclipse Foundation. All other trademarks are the property of their respective owners.

-->

To deploy your Helm chart on Google Cloud Platform (GCP), you need to follow these steps:

### Set up Google Kubernetes Engine (GKE):

 - Create a GKE cluster.

 - Configure kubectl to connect to your GKE cluster.

### Authenticate with GCP:

 - Ensure you have the gcloud CLI installed and authenticated.

### Deploy the Helm chart:

 - Use Helm to deploy your chart to the GKE cluster.


### Here are the detailed steps:

Note: Helm uses the Kubernetes context configured in your kubectl to determine where to deploy.
 When you authenticate with your GKE cluster using gcloud,
 it sets the current context in your kubectl configuration.
 Helm then uses this context to deploy the chart.


### 1. Set up Google Kubernetes Engine (GKE)

 1.1. Install gke-gcloud-auth-plugin for use with kubectl by following https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin 

  ```
  gcloud components install gke-gcloud-auth-plugin
  ```

 1.2. Create a GKE cluster

  ```
  gcloud container clusters create <your-cluster-name> --zone <zone-name>
  ```

 
 1.3. Enable Workload identity for cluster
 
  ```
  gcloud container clusters update <your-cluster-name> \
     --zone <zone-name> \
     --workload-pool=<your-gcp-project-id>.svc.id.goog
  ```

 1.4. Create a new node pool for cluster (you'll need have a service account to associate with the node pool,
   you will not be able to update this param later). Example: 
   
   ```
         gcloud container node-pools create <your-node-pool-name> \
          --cluster <your-cluster-name> \
          --service-account <your-gcp-service-account-email> \
          --zone <zone-name> \
          --machine-type n2-highcpu-32 \
          --num-nodes 3 \
          --workload-metadata=GKE_METADATA
   ```

 1.5. Delete `default-pool` node pull created automatically

 1.6. Get credentials for the cluster

`gcloud container clusters get-credentials <your-cluster-name> --zone <zone-name>`


 1.7. Verify Kubernetes Context

`kubectl config current-context`

  and ensure the output matches your GKE cluster.

### 2. Authenticate with GCP

 2.1 Authenticate with GCP

`gcloud auth login`

 2.2. Set the project

`gcloud config set project <your-gcp-project-id>`

### 3. Deploy the Helm chart

 3.1. Add the Helm repository if not already added

`helm repo add nxrm3-ha-repository <https://example.com/helm-charts>`

 3.2. Update the Helm repository

`helm repo update`

 3.3. Deploy the Helm chart
 Note: you need to update values.yaml with your values before deploying the Helm chart.
 More details in nxrm-ha/README.md file

``` 
cd nxrm3-ha-repository/nxrm-ha

helm install nxrm . -n nexuinstall
```

This will deploy your Helm chart to the GKE cluster in the `nexusinstall` namespace and automatically create `nexusrepo` namespace).

Make sure to replace <your-gcp-project-id> with your actual GCP project ID.
