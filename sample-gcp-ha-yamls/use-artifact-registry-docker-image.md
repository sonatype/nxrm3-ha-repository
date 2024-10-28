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

To use a Docker image from Google Artifact Registry as a container image source in Kubernetes,
 you need to follow these steps:

1. **Authenticate Docker to Google Artifact Registry**:
   ```sh
   gcloud auth configure-docker <your-region>-docker.pkg.dev
   ```

2. **Create a Kubernetes secret for Docker registry credentials**:
   ```sh
   kubectl create secret docker-registry gcr-json-key \
     --docker-server=<your-region>-docker.pkg.dev \
     --docker-username=_json_key \
     --docker-password="$(cat <path-to-your-service-account-key>.json)" \
     --docker-email=<your-email>
   ```
   
   kubectl create secret docker-registry gcr-json-key: 
   This part of the command creates a new secret named gcr-json-key of type docker-registry.  
   
--docker-server=<your-region>-docker.pkg.dev: 
Specifies the Docker registry server. Replace <your-region> with the appropriate region for your Google Artifact Registry.  

--docker-username=_json_key: 
Specifies the username for the Docker registry. For Google Artifact Registry, _json_key is used to indicate that a JSON key file will be used for authentication.  

--docker-password="$(cat <path-to-your-service-account-key>.json)":
 Specifies the password for the Docker registry. This is the content of the service account key file. Replace <path-to-your-service-account-key>.json with the path to your JSON key file.  

--docker-email=<your-email>: 
Specifies the email associated with the Docker registry account. Replace <your-email> with your email address.

3. **Reference the secret in your `statefulset.yaml`**:
   Update the `imagePullSecrets` section to include the secret you created.

   ```yaml
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: my-statefulset
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: my-app
     template:
       metadata:
         labels:
           app: my-app
       spec:
         imagePullSecrets:
           - name: gcr-json-key
         containers:
           - name: my-container
             image: <your-region>-docker.pkg.dev/<your-project-id>/<your-repo>/<your-image>:<tag>
             ports:
               - containerPort: 80
   ```

In this example:
- Replace `<your-region>`, `<your-project-id>`, `<your-repo>`, `<your-image>`, and `<tag>` with your specific details.
- Ensure the `imagePullSecrets` section references the secret created for Docker registry credentials.
