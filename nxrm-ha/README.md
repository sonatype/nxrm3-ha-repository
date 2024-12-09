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

# Helm Chart for High Availability (HA) and Resilient Deployments

This Helm chart configures the Kubernetes resources that are needed for HA or resilient Nexus Repository deployments in AWS, Azure, or on-premises.

- Have an idea for an improvement? Pro customers can submit ideas through [Sonatype's Ideas portal](https://ideas.sonatype.com/).
- If you encounter any problems/issues with the helm chart, please contact Sonatype support as support@sonatype.com

> **_NOTE:_** Sonatype does not support or plan to support using a Helm chart for deployments using embedded databases, which includes all OSS deployments. Using Kubernetes to manage an application with an embedded database is a leading cause of corruption, outages, and data loss.

---

# Pre-requisites
> **_Note:_**  Before upgrading your Nexus Repository instance, review the [Nexus Repository Release Notes](https://help.sonatype.com/en/release-notes.html) to evaluate any potential breaking changes.

Also be sure to review our [HA system requirements help documentation](https://help.sonatype.com/en/system-requirements-for-high-availability-deployments.html) and ensure that each instance meets our [normal Nexus Repository system requirements](https://help.sonatype.com/repomanager3/product-information/system-requirements).

### Sticky Sessions for Load Balancers/Ingress
> **_NOTE:_** Configuration of sticky sessions is not supported in this chart. If you require sticky sessions, you will need to configure this in your load balancer or ingress controller as applicable.

### Storage
The default configuration uses an emptyDir volume for storing Nexus Repository logs. However, this is only for demonstration purposes. For production, we strongly recommend that
you configure dynamic provisioning of persistent storage bound to a shared location, such as EFS/Azure File/NFS, which is accessible to all actives nodes in your Kubernetes cluster. 

> **_Note:_**  Versions **66.0.0 and older** of this chart only supported local storage (e.g., EBS, Azure Disk, locally attached disks for on-prem deployments). 
> 
> From version **68.0.0+**, we recommend and support using **shared storage** (e.g., EFS, Azure File, NFS for on-prem deployments). However, this chart is still compatible with local storage.

#### Continuing to use EBS/Azure Disk/on-prem local disk storage in versions 68.0.0+ - **(Not recommended)**
If you wish to continue using EBS/Azure Disk/on-prem local disk storage, you can do so as follows:
* Ensure the appropriate Container Storage Interface (CSI) driver(s) are installed on the Kubernetes cluster for your chosen cloud deployment.
* Set `pvc.volumeClaimTemplate.enabled` to `true`
* Set `pvc.accessModes` to `ReadWriteOnce`
* Set `pvc.storageSize` to the desired size of the volume. E.g., `50Gi`
* To use a built-in storage class, set `storageClass.name` to `gp2`, `managed-premium` or `premium-rwo` for EKS, AKS and GKE respectively. For  on-prem deployments specify the name of your custom storage class.
* Set `volumeBindingMode` to `WaitForFirstConsumer`
* Set `reclaimPolicy` to `Retain` or `Delete` depending on your requirements
* To use a custom storage class, in addition to the above:
  * Set `storageClass.enabled` to `true`
  * Set the `storageClass.provisioner` to the appropriate value (see the documentation for your storage provider for more details). E.g., `ebs.csi.aws.com`, `disk.csi.azure.com` or `pd.csi.storage.gke.io` for EKS, AKS and GKE respectively. For on-prem deployments:`see the CSI driver documentation for your storage provider` E.g., for local static provisioner see https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner
  * Additional parameters can be set as needed for your custom storage class using the `storageClass.parameters` field.

#### Migrating from local storage (i.e., EBS/Azure Disk/local disk) to shared storage (i.e., EFS/Azure File/NFS) for storing Nexus Repository logs

If you have installed version 66.0.0 or older of the nxrm-ha chart and wish to switch to using shared storage for Nexus Repository logs, please do as follows:

1. Back up all of your Nexus Repository pods' logs by logging in and generating a support zip for each one (see our [support zip help documentation](https://help.sonatype.com/en/support-features.html#creating-a-support-zip-in-a-high-availability-environment) to learn how).
2. Scale statefulset replicas to zero using commands like the following:
   * `kubectl get statefulsets -n nexusrepo`
   * `kubectl scale statefulsets -n nexusrepo <stateful set name> --replicas=0`
3. After scaling statefulset replicas to zero, delete the statefulset using a command like the following:
   *`kubectl delete statefulsets -n nexusrepo <stateful set name>`
4. Delete EBS/Azure disk/local disk PVCs using commands like the following: 
   * `kubectl get pvc -n nexusrepo`
   * `kubectl delete pvc -n nexusrepo <pvc 1> <pvc 2> <pvc n>`
   * If you have a custom storage class for EBS PVC/PV pair, delete that storage class as well.
4. Upgrade to the new version (68.0.0) of the nxrm-ha helm chart by taking the following steps:
   * Provision your shared storage (e.g., EFS/Azure File/NFS), and set appropriate permissions.
   * Update your custom values.yaml file for shared storage as detailed in the applicable section below for configuring dynamic persistent volume provisioning for your selected storage option. 
   * Run helm upgrade: `helm upgrade nxrm sonatype/nxrm-ha -f <your values.yaml> --version 68.0.0`
   * Scale replicas as needed.
5. Confirm all Nexus Repository pods start up and create new PVCs.
   * Confirm new PVCs were created and that they are bound appropriately depending on your configuration (i.e., EFS access points/Azure File shares/NFS mounts):
      * `kubectl get pvc -n nexusrepo` 
      * `kubectl describe pvc -n nexusrepo nexus-data-nxrm-nxrm-ha-0` 
      * `kubectl describe pvc -n nexusrepo nexus-data-nxrm-nxrm-ha-1`
      * Check that the `volume.beta.kubernetes.io/storage-provisioner` annotation in the PVC description is representative of your configuration (i.e., EFS/Azure File/NFS provisioner).
   * Confirm pods are up and running using commands like the following:
      * `kubectl get pods -n nexusrepo` 
      * `kubectl logs -n nexusrepo nxrm-nxrm-ha-0 -f` 
      * `kubectl logs -n nexusrepo nxrm-nxrm-ha-1 -f` 
      * `kubectl logs -n nexusrepo nxrm-nxrm-ha-2 -f`

#### Cloud deployments (AWS/Azure/GCP)
* Ensure the appropriate Container Storage Interface (CSI) driver(s) are installed on the Kubernetes cluster for your chosen cloud deployment.
  * For AWS, see our [documentation on high availability deployments in AWS](https://help.sonatype.com/en/option-3---high-availability-deployment-in-amazon-web-services--aws-.html)
  * For Azure, see our [documentation on high availability deployments in Azure](https://help.sonatype.com/en/option-4---high-availability-deployment-in-azure.html)
  * For GCP, see our [documentation on high availability deployments in GCP](https://help.sonatype.com/en/option-4---high-availability-deployment-in-gcp.html)

#### On-premises deployments
1. Set up an NFS server and make it accessible to all worker nodes in your Kubernetes cluster.
2. See our [documentation on on-premises high availability deployments using Kubernetes](https://help.sonatype.com/en/option-2---on-premises-high-availability-deployment-using-kubernetes.html) for more information


## Format Limitations
HA supports all formats that PostgreSQL supports.


## Deployment Configuration

### Secrets
The chart requires three secrets namely:
* License secret: stores your Nexus Repository Pro license
* Database secret: stores your database credentials: username, password and host
* Initial admin password secret: stores your initial admin password for Nexus Repository


#### Injecting required secrets into your Nexus Repository pod
The chart provides fours ways of injecting secrets into your Nexus Repository pod namely:
* [External secret operator](https://external-secrets.io/latest/): recommended as it supports several external secret stores (AWS, Azure, GCP etc).
  * Irrespective of whether you're installing on AWS/Azure, the following steps are needed to configure the nxrm-ha helm chart to use the External Secrets Operator:
    - [Install external secret operator](https://external-secrets.io/latest/)
    - Create your secrets in your external secret store (e.g. AWS Secrets Manager, Azure Key Vault, Google Secret Manager etc)
    - In your values.yaml:
        - Set `externalsecrets.enabled`
        - Set the `externalsecrets.secretstore.spec` to the correct one (e.g. AWS, Azure, GCP, HashiCorp Vault) for your provider. (There are examples for AWS, Azure, GCP in the default values.yaml provided with this helm chart). See https://external-secrets.io/latest/ for more examples.
        - Set the `externalsecrets.secrets.database.providerSecretName` to the name of the secret containing your database credentials in your external secret store. E.g. if using AWS, this should be the name of the secret in your AWS Secrets Manager. If using Azure, this should be the name of the secret in your Azure Key Vault
        - Set the `externalsecrets.secrets.database.dbUserKey` to the name of the key in the secret which contains your database username.
        - Set the `externalsecrets.secrets.database.dbPasswordKey` to the name of the key in the secret which contains your database password.
        - Set the `externalsecrets.secrets.database.dbHostKey` to the name of the key in the secret which contains your database host.
        - Set the `externalsecrets.secrets.admin.providerSecretName` to the name of the secret containing your Nexus Repository admin password in your external secret store. E.g. if using AWS, this should be the name of the secret in your AWS Secrets Manager. If using Azure, this should be the name of the secret in your Azure Key Vault
        - Set the `externalsecrets.secrets.admin.adminPasswordKey` to the name of the key in the secret which contains your initial Nexus Repository admin password.
        - Set the `externalsecrets.secrets.license.providerSecretName` to the name of the secret containing your Nexus Repository license in your external secret store. E.g. if using AWS, this should be the name of the secret in your AWS Secrets Manager. If using Azure, this should be the name of the secret in your Azure Key Vault
        - Ensure `secret.azure.nexusSecret.enabled` and `azure.keyvault.enabled` are `false`

* [Secret Store CSI Driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver): If you're running on AWS or Azure and do not wish to use the external secrets operator, 
 you can use the secret store csi driver configuration. See [secretprovider.yaml](templates%2Fsecretprovider.yaml) and configuration table below for more details.
* Use the provided secrets templates:
  * [database-secret.yaml](templates%2Fdatabase-secret.yaml)
  * [license-config-mapping.yaml](templates%2Flicense-config-mapping.yaml)
  * [nexus-admin-secret.yaml](templates%2Fnexus-admin-secret.yaml)

### AWS
* Set `aws.enabled` to `true`.

#### Configuration for dynamic persistent volume provisioning
* Set `storageClass.enabled` to `true`
* Set `storageClass.provisioner` to `efs.csi.aws.com`
* Set `storageClass.parameters` to
    ```
       provisioningMode: efs-ap 
       fileSystemId: "<your efs file system id>"
       directoryPerms: "700"
    ```
* Set `pvc.volumeClaimTemplate.enabled` to `true`

#### Secrets
If you do not wish to the [external secrets operator](https://external-secrets.io/latest/) for providing your secrets into your Nexus Repository pods, then you may use AWS Secret Manager directly.
AWS Secret Manager is disabled by default. If you would like to store your database secrets and license in AWS Secrets Manager, do as follows:
* Set `aws.secretmanager.enabled` to `true`.
   * Database credentials:
      * Store database credentials (i.e., host, user and password) in AWS secret manager.
      * In your values.yaml, do the following:
         * Set the keys and aliases to use for getting the database credentials from secrets manager:  
           `db:
           user: username
           userAlias: nxrm_db_user
           password: password
           passwordAlias: nxrm_db_password
           host: host
           hostAlias: nxrm_db_host`
            * Update the `secret.aws.rds.arn` to your Secret Manager ARN containing database credentials.
   * Initial Nexus Repository Admin Password
      * Store initial Nexus repository Admin password in AWS Secrets Manager.
      * Set the `secret.nexusAdmin.name` to the key you used in Secrets Manager.
      * Set the `secret.nexusAdmin.alias` to the alias you would like the helm chart to use.
      * Update the `secret.aws.adminpassword.arn` to your Secret Manager ARN containing initial admin password.
   * License
      * Store your Nexus Repository Pro license in AWS Secrets Manager.
      * Update the `secret.aws.license.arn` to your Secret Manager ARN containing your Nexus Repository Pro license.
  * Encryption Keys
    * Store the json file containing your encryption keys in AWS Secrets Manager
    * Set `secret.aws.nexusSecret.enabled` and `secret.nexusSecret.enabled` to true
    * Set `secret.aws.nexusSecret.arn` to the ARN of your secret in AWS Secrets Manager
    * Ensure `secret.azure.nexusSecret.enabled` and `azure.keyvault.enabled` are false

##### External Secrets Operator
- Ensure you have installed the [external secrets operator](https://external-secrets.io/latest/)
- Ensure you have granted the necessary permissions for accessing your external secret store:
- You'll need an IAM role with necessary permissions and associate that IAM role with the service account used by your pods:
- See [External secrets operator EKS service account credentials](https://external-secrets.io/latest/provider/aws-secrets-manager/#eks-service-account-credentials) for more details.

### Azure
* Set `azure.enabled` to `true`.

#### Configuration for dynamic persistent volume provisioning
You can either use one of the built-in storage classes for Azure File or create your own storage class.

##### Using built-in storage class
* Ensure you have enabled the built-in storage classes on your AKS cluster. For more information, see the Azure file dynamic provisioning section of [our documentation on high availability deployments in Azure](https://help.sonatype.com/en/option-4---high-availability-deployment-in-azure.html)
* Set `storageClass.enabled` to `false`
* Set `storageClass.name` to one of the in-built storage classes for Azure file, such as azurefile-csi-premium, azurefile-premium, azurefile, or azurefile-csi
* Set `storageClass.provisioner` to `file.csi.azure.com`
* Set the `pvc.volumeClaimTemplate.enabled` parameter to `true`

##### Creating your own storage class
If you would like to create your own storage class instead of using the built-in ones, do as follows:

* Set `storageClass.enabled` to `true`
* Set `storageClass.name` to `nexus-log-storage`
* Set `storageClass.provisioner` to `file.csi.azure.com`
* Set `storageClass.mountOptions` to
    ```
   - dir_mode=0777
   - file_mode=0777
   - uid=0
   - gid=0
   - mfsymlinks
   - cache=strict # https://linux.die.net/man/8/mount.cifs
   - nosharesock 
    ```
* Set `storageClass.parameters.skuName` to `Premium_LRS`
* Set `pvc.volumeClaimTemplate.enabled` to `true`

#### Secrets
If you do not wish to the [external secrets operator](https://external-secrets.io/latest/) for providing your secrets into your Nexus Repository pods, then you may use Azure Key Vault directly.
Azure Key Vault is disabled by default. If you would like to store your database secrets and license in Azure Key Vault, do as follows:
* Set `azure.keyvault.enabled` to `true`.
   * Database credentials
      * Store database credentials (i.e., host, user, and password) in Azure Key Vault.
      * In your values.yaml, do the following:
         * Set the keys to use for getting the database credentials from Azure Key Vault:  
           `db:
           user: username
           password: password
           host: host`
         * Set the parameters nested in `secret.azure` accordingly.
   * Initial Nexus Repository Admin Password
      * Store initial Nexus repository Admin password in Azure Key Vault.
      * Set the `secret.nexusAdmin.name` to the key you used in Azure Key Vault.
   * License
      * Store your Nexus Repository Pro license in Azure Key Vault.
      * Set the `secret.license.name` to Azure Key Vault secret containing your Nexus Repository Pro license.
  * Encryption Keys
    * Store the json file containing your encryption keys in Azure Key Vault
    * Specify your key vault name in `secret.azuee.keyvaultName`
    * Set `secret.azure.nexusSecret.enabled` and `secret.nexusSecret.enabled` to true
    * Ensure `secret.aws.nexusSecret.enabled ` and `aws.secretmanager.enabled` are false


##### External Secrets Operator
- Ensure you have installed the [external secrets operator](https://external-secrets.io/latest/)
- Ensure you have granted the necessary permissions for accessing your external secret store:
- You'll need to create a service account and create a trust relationship between Azure AD and that Kubernetes service account:
    - See [Workload identity](https://external-secrets.io/latest/provider/azure-key-vault/#workload-identity)
    - See 'Referenced Service Account' section of [Workload identity](https://external-secrets.io/latest/provider/azure-key-vault/#workload-identity)

##### Guidance for setting up permissions needed for External Secrets Operator on Azure (AKS)
- According to https://external-secrets.io/latest/provider/azure-key-vault/#authentication the recommended way to authenticate external secrets operator for Azure Key Vault is through workload identity.
- We tried this out by following the steps on the page at: https://azure.github.io/azure-workload-identity/docs/quick-start.html which is referenced from https://external-secrets.io/latest/provider/azure-key-vault/#authentication :
    - According to https://azure.github.io/azure-workload-identity/docs/quick-start.html you can either use the azwi (Azure Workload Identity) tool for Azure Active Directory (AAD) application or use az cli for  user-assigned managed identity, we opted for azwi tool. See next section for details.

##### Setting up permissions using The Azure Workload Identity tool for Azure Active Directory (AAD) application
- Install azwi :  See https://azure.github.io/azure-workload-identity/docs/installation/azwi.html for brew command
- Open a shell
    - [Set the following env variables](https://azure.github.io/azure-workload-identity/docs/quick-start.html#2-export-environment-variables):
      ```
      export APPLICATION_NAME=nexus-repo-aks-aad
      export KEYVAULT_NAME=test-nexusha-secrets (your key vault name)
      export KEYVAULT_SCOPE=$(az keyvault show --name "${KEYVAULT_NAME}" --query id -o tsv)
      export SERVICE_ACCOUNT_NAMESPACE=nexusrepo (must be same as namespace in values.yaml of ha helm chart)
      export SERVICE_ACCOUNT_NAME=nexus-repository-dev-ha-sa. (Must be same as that specified in values.yaml of ha helm chart)
      export SERVICE_ACCOUNT_ISSUER=$(az aks show --resource-group nexus-repo-ha --name nexus-repo-ha-aks --query "oidcIssuerProfile.issuerUrl" -otsv)
      ```

    - [Create Key Vault](https://azure.github.io/azure-workload-identity/docs/quick-start.html#3-create-an-azure-key-vault-and-secret)

        - [Create an AAD application or user-assigned managed identity and grant permissions to access the secret](https://azure.github.io/azure-workload-identity/docs/quick-start.html#4-create-an-aad-application-or-user-assigned-managed-identity-and-grant-permissions-to-access-the-secret)
            - `azwi serviceaccount create phase app --aad-application-name "${APPLICATION_NAME}"`
            - Output should be like:
                ```
                INFO[0000] No subscription provided, using selected subscription from Azure CLI: REDACTED
                INFO[0005] [aad-application] created an AAD application  clientID=REDACTED name=azwi-test objectID=REDACTED
                WARN[0005] --service-principal-name not specified, falling back to AAD application name
                INFO[0005] [aad-application] created service principal   clientID=REDACTED name=azwi-test objectID=REDACTED
                ```
            - Make a note of the client id value in the output as you’ll need it for your helm values.yaml. You’ll also need to know your Azure tenant id for your helm values.yaml. You can find out from the Azure portal or use this command to find out from the AAD application you just created:
              `az ad sp list --display-name "${APPLICATION_NAME}" --query '[0].appOwnerOrganizationId' -otsv`

            - Set access policy for the AAD application or user-assigned managed identity to access the keyvault secret:
                - If your key vault is using RBAC use the command below
                  ```
                  export APPLICATION_CLIENT_ID="$(az ad sp list --display-name "${APPLICATION_NAME}" --query '[0].appId' -otsv)"
                  az role assignment create --role "Key Vault Secrets User" --assignee $APPLICATION_CLIENT_ID --scope $KEYVAULT_SCOPE
                  ```
                  (RBAC Key Vault command source: https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access#configure-managed-identity )

                - If your Key vault is not using RBAC (i.e. if you’re using user-assigned managed identity) then you can use command below:
                  ```
                  export APPLICATION_CLIENT_ID="$(az ad sp list --display-name "${APPLICATION_NAME}" --query '[0].appId' -otsv)"
                  az keyvault set-policy --name "${KEYVAULT_NAME}" --secret-permissions get --spn "${APPLICATION_CLIENT_ID}"
                  ```
                  (source: https://azure.github.io/azure-workload-identity/docs/quick-start.html#4-create-an-aad-application-or-user-assigned-managed-identity-and-grant-permissions-to-access-the-secret )
            - Skip [Create a Kubernetes service account](https://azure.github.io/azure-workload-identity/docs/quick-start.html#5-create-a-kubernetes-service-account)
                - We will skip this since our nxrm-ha helm chart will be doing this for us. We’ll just need to make sure we specify the appropriate annotations and labels to the service account the helm chart will create (see below)

            - [Establish federated identity credential between the identity and the service account issuer & subject](https://azure.github.io/azure-workload-identity/docs/quick-start.html#6-establish-federated-identity-credential-between-the-identity-and-the-service-account-issuer--subject)
              ``` 
                azwi serviceaccount create phase federated-identity \ 
                --aad-application-name "${APPLICATION_NAME}" \ 
                --service-account-namespace "${SERVICE_ACCOUNT_NAMESPACE}" \ 
                --service-account-name "${SERVICE_ACCOUNT_NAME}" \ 
                --service-account-issuer-url "${SERVICE_ACCOUNT_ISSUER}"
              ```
                - Output should be like:
                  ```
                    INFO[0000] No subscription provided, using selected subscription from Azure CLI: REDACTED
                    INFO[0032] [federated-identity] added federated credential  objectID=REDACTED subject="system:serviceaccount:default:workload-identity-sa"
                  ```
            - Update your nxrm-ha values.yaml:
                - Service account section:
                  ```
                  serviceAccount:
                     enabled: true
                     name: nexus-repository-dev-ha-sa #
                     labels:
                        azure.workload.identity/use: "true"
                     annotations:
                        azure.workload.identity/client-id: ab67cbbb-e374-4586-bcb6-8d80df659b41
                        azure.workload.identity/tenant-id: bd28fc0b-f086-430f-ac20-16268536c81f
                  ```
                - External secrets:
                  ```
                  externalsecrets:
                     enabled: true
                     secretstore:
                        name: nexus-secret-store
                        spec:
                           provider:
                              azurekv:
                                 authType: WorkloadIdentity
                                 vaultUrl: "https://test-nexusha-secrets.vault.azure.net/" #use your key vault url here
                                 serviceAccountRef:
                                    name: nexus-repository-dev-ha-sa # use same service account name as specified in serviceAccount.name
                  ```
                  
### GCP

 * Update values.yaml
   <a id="enable-service-account"></a>
   1. Enable service account  (you’ll need the name of the existing Google service account - there is a chapter below on how to create it)
  
       ```
         serviceAccount:
           enabled: true
           name: nexus-repository-deployment-sa
           labels: {}
           annotations:
             iam.gke.io/gcp-service-account: <service-account-name>@<project-id>.iam.gserviceaccount.com <- your GCP project service account e-mail
        
       ```

   2. Enable ingress 
        ```
        ingress:
          name: "nexus-ingress"
          enabled: true
        ```  
   3. Update ingress properties to correspond to GKE controller class https://cloud.google.com/kubernetes-engine/docs/how-to/load-balance-ingress#create-ingress 
        ```
        ingress:
          name: "nexus-ingress"
          enabled: true
          ...
          defaultRule: true
          additionalRules: null
          ingressClassName: gce
          ...
          annotations:
            kubernetes.io/ingress.class: "gce"
        ```
   4. Enable Nexus NodePort/ClusterIP service 
    
         ```
         service:  #Nexus Repo NodePort Service
           annotations: {}
           nexus:
             enabled: true
         ```

   5. Now you can update secrets separately (follow steps 6, 7, 8 below) 
      OR install ESO ([External Secret Operator]https://external-secrets.io/latest/introduction/getting-started/)
      ESO is the recommended approach for production.

        ```
        helm install external-secrets \
           external-secrets/external-secrets \
            -n external-secrets \
            --create-namespace
        ```
      and use external secrets from Google Secret Manager (https://external-secrets.io/latest/provider/google-secrets-manager/)
   

   6. Enable db secret 
        ```    
        secret:
          secretProviderClass: "secretProviderClass"
          provider: provider # e.g. aws, azure etc
          dbSecret:
            enabled: true # Enable to apply database-secret.yaml which allows you to specify db credentials
          db:
            user: nxrm
            userAlias: nxrm
            password: nxrm
            passwordAlias: nxrm
            host: 10.10.0.3
        ```

   7. (Optional) Set default password for Nexus instances 
        ```
          nexusAdminSecret:
            enabled: true # Enable to apply nexus-admin-secret.yaml which allows you to the initial admin password for nexus repository
            adminPassword: admin123 #You should change this when you login for the first time
        ```

   8. Set license (use base64 to encode file)  
        ```
          license:
            name: test-users.lic
            licenseSecret:
              enabled: true
              fileContentsBase64: cylwwtYx6Fg1CUa9yGqBuhGhgc4IS67Ha/+uvxSpA  == your base64 encoded license file == Gd7Z3+WS/0LIeugxSIa+ZDqtg7AR+U3d9ZJA==
              mountPath: /var/nexus-repo-license
        ```
      You can also specify the license file with your helm command as in:
      `--set-file secret.license.licenseSecret.file=<path to your license file>`

#### How to allow access to GCP credentials from deployed Kubernetes cluster (GKE)

  To allow a container in a GKE cluster node to access Application Default Credentials (ADC),
  you need to ensure that the GKE nodes have the necessary IAM roles and that the container is configured to use ADC. Here are the steps:

   1.  Ensure GKE Nodes Have the Necessary IAM Roles:
       When you create the cluster, ensure that you are using a service account that has required IAM roles for the GKE nodes
       NOTE: It's important to associate GCP service account with cluster node pool when you create node pool.
       Current GCP limitations doesn't allow to update service account for nodes, so you need to recreate the node pool if you need to change the service account.

       **Check step `2.c` if you need to create a new account**

       You may assign the necessary IAM roles to the service account. For example, if your application needs access to write in Google Cloud Storage,
       you would assign the `roles/storage.objectAdmin` role.
     
        ```
        gcloud projects add-iam-policy-binding <your-project-id> \
          --member "serviceAccount:<your-gke-node-service-account>" \
          --role "roles/storage.objectAdmin"
        ```

   2. Configure the GKE Cluster (if it's not configured at the creation) to Use Workload Identity:
      Workload Identity allows Kubernetes service accounts to act as Google service accounts. 
      This is the recommended way to provide credentials to applications running on GKE.
      We do not recommend using IAM principal identifiers to configure Workload Identity Federation,
      because there are a few limitations that apply to GoogleCloud Storage usage
      (you may need to enable uniform bucket-level access for your buckets etc…, more details here [Identity federation: products and limitations](https://cloud.google.com/iam/docs/federated-identity-supported-services)
      So we recommend to use this method:  [Alternative: link Kubernetes ServiceAccounts to IAM](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam) 

   * 2.a
   Enable Workload Identity:

        ```    
        gcloud container clusters update <your-cluster-name> \
          --zone <your-cluster-zone> \
          --workload-pool=<your-project-id>.svc.id.goog
        ```
        ```
         gcloud container node-pools update NODEPOOL_NAME \
         --cluster=CLUSTER_NAME \
         --zone=COMPUTE_ZONE \
         --workload-metadata=GKE_METADATA
         ```
   * 2.b
   Create a Kubernetes Service Account:
    
         ```
         kubectl create serviceaccount <your-k8s-service-account>
         ```
   * 2.c
      Create a Google Service Account:
        ```
        gcloud iam service-accounts create <your-gsa-name> 
        ```
   * 2.d
      Grant required roles to your <your-gsa-name> account

        ```
         gcloud projects add-iam-policy-binding <your-project-id> \
         --member "serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
         --role "roles/storage.admin"
        
        gcloud projects add-iam-policy-binding <your-project-id> \
        --member="serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
        --role="roles/compute.viewer"
        
        // if your intent to use ESO   
        gcloud projects add-iam-policy-binding <your-project-id> \
        --member="serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
        --role="roles/secretmanager.admin"
        
        // if your intent to use ESO    
        gcloud projects add-iam-policy-binding <your-project-id> \
        --member="serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
        --role="roles/iam.serviceAccountTokenCreator"
        
        // if your intent to use Google Artifactory to store Nexus docker images for deploy
        gcloud projects add-iam-policy-binding <your-project-id> \
        --member="serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
        --role="roles/artifactregistry.admin"
        ```
   * 2.e
      Allow the Kubernetes Service Account to Act As the Google Service Account:

        ```
        gcloud iam service-accounts add-iam-policy-binding <your-gsa-name>@<your-project-id>.iam.gserviceaccount.com \
          --role roles/iam.workloadIdentityUser \
          --member "serviceAccount:<your-project-id>.svc.id.goog[<your-namespace>/<your-k8s-service-account>]"
        ```
   * 2.f
        (Optional) Annotate the Kubernetes Service Account:
    
        ```
            kubectl annotate serviceaccount <your-k8s-service-account> \
            --namespace <your-namespace> \
            iam.gke.io/gcp-service-account=<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com
        ```
        This step is optional - you may annotate the service account in `values.yaml` of the helm chart.
        For more information, see [Enable service account](#enable-service-account).

3. Deploy Your Application:

Ensure your application is configured to use ADC. When running on GKE with Workload Identity,
the ADC will automatically use the credentials provided by the annotated Kubernetes service account.

#### Configuration for dynamic persistent volume provisioning
* Ensure you have enabled the built-in storage classes on your GCP cluster. 
* You need to install Google CSI Filestore driver on your GKE cluster. 
* For more information, see the [GCP documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/storage-overview#filestore)
* Set `storageClass.enabled` to `true`
* Set `storageClass.provisioner` to `filestore.csi.storage.gke.io`
* Set `storageClass.parameters` to
    ```
         tier: enterprise
         multishare: "true"
    ```
* Set `pvc.volumeClaimTemplate.enabled` to `true`


##### External Secrets Operator
- Ensure you have installed the [external secrets operator](https://external-secrets.io/latest/)
- Ensure you have granted the necessary permissions for accessing your external secret store:
- You'll need to create a k8s service account and create a link between GCP service account and that Kubernetes service account:
    - See [Workload identity](https://external-secrets.io/latest/provider/google-secrets-manager/#workload-identity)
    - See 'Using Service Accounts directly' section [Using Service Accounts directly](https://external-secrets.io/latest/provider/google-secrets-manager/#using-service-accounts-directly)
- Enable the external secrets operator in your values.yaml:
    ```
    externalsecrets:
      enabled: true
      secretstore:
        name: nexus-secret-store
        spec:
          provider:
            gcpsecretsmanager:
              authType: WorkloadIdentity
              serviceAccountRef:
                name: nexus-repository-deployment-sa
    ```
- Ensure you have created the necessary secrets in GCP Secret Manager and have the necessary permissions to access them.
Check section above "Injecting required secrets into your Nexus Repository pod" for more details.

###### Guidance for setting up permissions needed for External Secrets Operator on GCP (EKS)

- For your GSP service account, you'll need to add an additional permissions to access the secret in GCP Secret Manager:

```
gcloud projects add-iam-policy-binding <your-project-id> \
--member="serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
--role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding  <your-project-id> \
--member="serviceAccount:<your-gsa-name>@<your-project-id>.iam.gserviceaccount.com" \
--role="roles/iam.serviceAccountTokenCreator"
```



### On-premises
The chart doesn't install any cloud-specific resources when `aws.enabled` and `azure.enabled` are set to `false`.

#### Configuration for dynamic persistent volume provisioning
* You must already have an NFS Server, and it must be accessible to all worker nodes in your Kubernetes cluster.
* Install the [NFS subdir external provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) using the [helm chart](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner?tab=readme-ov-file#with-helm).
  * At the time of writing, the helm installation command is as shown below.
  ```
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
  helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=x.x.x.x --set nfs.path=/exported/path --set storageClass.create=true
  ``` 
  * We have added `--set storageClass.create=true` to the above command in order to create the default nfs storage class bundled with the helm chart.
  * Confirm that the pod for the nfs-subdir-external-provisioner is running:
    * At the time of writing, the pod had a 'app=nfs-subdir-external-provisioner' label. Thus, you can confirm it is running using the following: `kubectl get pods -A -l app=nfs-subdir-external-provisioner`
  * Confirm that the default storage class was created:
    * At the time of writing, the default storage class was 'nfs-client'. Thus, you can confirm its creation using `kubectl get sc nfs-client`
* For nxrm-ha helm chart, do the following:
  * Set `storageClass.enabled` to `false`
  * Set `storageClass.name` to `nfs-client`
  * Set `pvc.volumeClaimTemplate.enabled` to `true`


#### Secrets
* Database credentials
   * Set `secret.dbSecret.enabled` to `true` to enable [database-secret.yaml](nxrm-ha%2Ftemplates%2Fdatabase-secret.yaml) for storing database secrets.
   * Specify values for [database-secret.yaml](nxrm-ha%2Ftemplates%2Fdatabase-secret.yaml).
* Initial Nexus Repository Admin Password
   * Set `secret.nexusAdminSecret.enabled` to `true` to enable [nexus-admin-secret.yaml](nxrm-ha%2Ftemplates%2Fnexus-admin-secret.yaml) for storing initial Nexus Repository admin password secret.
   * Specify values for [nexus-admin-secret.yaml](nxrm-ha%2Ftemplates%2Fnexus-admin-secret.yaml).
* License
   * Set the `secret.license.licenseSecret.enabled` to `true` to enable [license-config-mapping.yaml](nxrm-ha%2Ftemplates%2Flicense-config-mapping.yaml) for storing your Nexus Repository Pro license.
   * Specify values for [license-config-mapping.yaml](nxrm-ha%2Ftemplates%2Flicense-config-mapping.yaml).
* Encryption Keys
    * Set `secret.nexusSecret.enabled` to true
    * Ensure `secret.azure.nexusSecret.enabled`, `azure.keyvault.enabled`, `secret.aws.nexusSecret.enabled` and `aws.secretmanager.enabled` are false

## Installing this Chart
You can install this helm chart from the git repository or sonatype helm index.

### From git repository
1. Check out this git repository.

2. Enter your custom values in the supplied values.yaml.  

3. Install this chart using the following:
  
```helm install nxrm nxrm3-ha-repository/nxrm-ha -f values.yaml```
  
4. Get the Nexus Repository link using the following:
  
```kubectl get ingresses -n nexusrepo```

### From Sonatype Helm index

1. Add the sonatype repo to your helm:

   ```helm repo add sonatype https://sonatype.github.io/helm3-charts/ ```

2. Enter your custom values in the supplied values.yaml.
3. Install this chart using the following:
```helm install nxrm sonatype/nxrm-ha -f values.yaml```
4. Get the Nexus Repository link using the following:
```kubectl get ingresses -n nexusrepo```

### Example helm install with options

Replace below commands with your actual values

#### OnPrem Deployments

```
helm install nxha1 \
--set storageClass.name=nfs \
--set secret.license.licenseSecret.enabled=true \
--set-file secret.license.licenseSecret.file=./nx-license-file.lic \
--set pvc.volumeClaimTemplate.enabled=true \
--set secret.dbSecret.enabled=true \
--set secret.db.host=postgres-host.mydomain \
--set secret.db.user=nexus \
--set secret.db.password=nexus123 \
--set secret.nexusAdminSecret.enabled=true \
--set secret.nexusAdminSecret.adminPassword="admin123" \
--set service.nexus.enabled=true \
sonatype/nxrm-ha
```

---
## Nexus Secrets

---

## Health Check
You can use the following commands to perform various health checks:
  
See a list of releases:
  
  ```helm list```
  
 Check pods using the following:
  
  ```kubectl get pods -n nexusrepo```
  
Check the Nexus Repository logs with the following:
  
  ```kubectl logs <pod_name> -n nexusrepo nxrm-app```

---

## Uninstall
To uninstall the deployment, use the following:
  
  ```helm uninstall nxrm```
  
After removing the deployment, ensure that the namespace created by the helm chart is deleted and that Nexus Repository is not listed when using the following:
  
  ```helm list```

> **_Note:_** If you specified a namespace during chart installation (e.g., helm install nxrm3 . --create-namespace --namespace <customnamespace>), you will need to remove this namespace after running the uninstall command for the helm chart. The uninstall command will only remove the namespace created by the helm chart itself.

## Configuration

The following table lists the configurable parameters of the Nexus chart and their default values.

| Parameter                                                   | Description                                                                                                                                                                                                                                                                                                                                                                      | Default                                                                                                             |
|-------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| `namespaces.nexusNs.enabled`                                | Whether a namespace should be created for the Kubernetes resources needed Nexus Repository pod(s)                                                                                                                                                                                                                                                                                | `true`                                                                                                              |
| `namespaces.nexusNs.name`                                   | The namespace into which Kubernetes resources for Nexus Repository are installed into, if set to `''` the release namespace is used                                                                                                                                                                                                                                              | `nexusrepo`                                                                                                         |
| `namespaces.cloudwatchNs.enabled`                           | Whether a namespace should be created to install the Kubernetes resources needed by fluentbit                                                                                                                                                                                                                                                                                    | `false`                                                                                                             |
| `namespaces.cloudwatchNs.name`                              | The namespace into which Kubernetes resources for fluentbit are installed when fluentbit is enabled                                                                                                                                                                                                                                                                              | `amazon-cloudwatch`                                                                                                 |
| `namespaces.externaldnsNs`                                  | The namespace into which Kubernetes resources for externaldns are installed when externaldns is enabled                                                                                                                                                                                                                                                                          | `nexus-externaldns`                                                                                                 |
| `serviceAccount.enabled`                                    | Whether or not to create a Kubernetes Service Account object                                                                                                                                                                                                                                                                                                                     | `false`                                                                                                             |
| `serviceAccount.name`                                       | The name of a Kubernetes Service Account object to create in order for Nexus Repository pods to access resources as needed                                                                                                                                                                                                                                                       | `nexus-repository-deployment-sa`                                                                                    |
| `serviceAccount.annotations`                                | Annotations for the Kubernetes Service Account object.                                                                                                                                                                                                                                                                                                                           | `null`                                                                                                              |
| `azure.enabled`                                             | Set this to true when installing this chart on Azure                                                                                                                                                                                                                                                                                                                             | `false`                                                                                                             |
| `azure.keyvault.enabled`                                    | Set this to true when installing this chart on Azure and you would like the Nexus Repository pod to pull database credentials and license from azure Key Vault                                                                                                                                                                                                                   | `false`                                                                                                             |
| `aws.enabled`                                               | Set this to true when installing this chart on AWS                                                                                                                                                                                                                                                                                                                               | `false`                                                                                                             |
| `aws.clusterRegion`                                         | The AWS region containing your Kubernetes cluster.                                                                                                                                                                                                                                                                                                                               | `us-east-1`                                                                                                         |
| `aws.secretmanager.enabled`                                 | Set this to true when installing this chart on AWS and you would like the Nexus Repository pod to pull database credentials and license from AWS Secret Manager                                                                                                                                                                                                                  | `false`                                                                                                             |
| `aws.externaldns.enabled`                                   | Set this to true when installing this chart on AWS and you would like to setup [externaldns](https://github.com/kubernetes-sigs/external-dns)                                                                                                                                                                                                                                    | `false`                                                                                                             |
| `aws.externaldns.domainFilter`                              | Domain filter for [externaldns](https://github.com/kubernetes-sigs/external-dns)                                                                                                                                                                                                                                                                                                 | `example.com`                                                                                                       |
| `aws.externaldns.awsZoneType`                               | The hosted zone type. See [externaldns](https://github.com/kubernetes-sigs/external-dns)                                                                                                                                                                                                                                                                                         | `private`                                                                                                           |
| `aws.fluentbit.enabled`                                     | Set this to true when installing this chart on AWS and you would like to install Fluentbit so that Nexus Repository logs can be sent to AWS Cloud Watch                                                                                                                                                                                                                          | `false`                                                                                                             |
| `aws.fluentbit.fluentbitVersion`                            | The fluentbit version                                                                                                                                                                                                                                                                                                                                                            | `2.28.0`                                                                                                            |
| `aws.fluentbit.clusterName`                                 | The name of your Kubernetes cluster. This is required by fluentbit                                                                                                                                                                                                                                                                                                               | `nxrm-nexus`                                                                                                        |
| `statefulset.replicaCount`                                  | The desired number of Nexus Repository pods                                                                                                                                                                                                                                                                                                                                      | 3                                                                                                                   |
| `statefulset.clustered`                                     | Determines whether or not Nexus Repository should be run in clustered/HA mode. When this is set to false, the search differences [here](https://help.sonatype.com/repomanager3/planning-your-implementation/resiliency-and-high-availability/high-availability-deployment-options#HighAvailabilityDeploymentOptions-SearchFeatureDifferences) do not apply.                      | true                                                                                                                |
| `statefulset.additionalVolumes`                             | Additional volumes to associate with the Nexus Repository container                                                                                                                                                                                                                                                                                                              | `null`                                                                                                              |
| `statefulset.additionalVolumeMounts`                        | Additional volume mounts for the additional volumes associated with the Nexus Repository container                                                                                                                                                                                                                                                                               | `null`                                                                                                              |
| `statefulset.additionalContainers`                          | Additional containers to associate with the Nexus Repository pod                                                                                                                                                                                                                                                                                                                 | `null`                                                                                                              |
| `statefulset.annotations`                                   | Annotations to enhance statefulset configuration                                                                                                                                                                                                                                                                                                                                 | {}                                                                                                                  |
| `statefulset.podAnnotations`                                | Pod annotations                                                                                                                                                                                                                                                                                                                                                                  | {}                                                                                                                  |
| `statefulset.nodeSelector`                                  | Node selectors                                                                                                                                                                                                                                                                                                                                                                   | {}                                                                                                                  |
| `statefulset.hostAliases`                                   | Aliases for IPs in /etc/hosts                                                                                                                                                                                                                                                                                                                                                    | []                                                                                                                  |
| `statefulset.postStart.command`                             | Command to run after starting the container                                                                                                                                                                                                                                                                                                                                      | `null`                                                                                                              |
| `statefulset.preStart.command`                              | Command to run before starting the container                                                                                                                                                                                                                                                                                                                                     | `null`                                                                                                              |
| `statefulset.initContainers`                                | Init containers to run before main containers                                                                                                                                                                                                                                                                                                                                    | An init container which creates directories needed for logging and give the Nexus Repository user write permissions |
| `statefulset.container.image.repository`                    | The Nexus repository image registry URL                                                                                                                                                                                                                                                                                                                                          | sonatype/nexus3                                                                                                     |
| `statefulset.container.image.nexusTag`                      | The Nexus repository image tag                                                                                                                                                                                                                                                                                                                                                   | latest                                                                                                              |
| `statefulset.container.resources.requests.cpu`              | The minimum cpu the Nexus repository pod can request                                                                                                                                                                                                                                                                                                                             | 4                                                                                                                   |
| `statefulset.container.resources.requests.memory`           | The minimum memory the Nexus repository pod can request                                                                                                                                                                                                                                                                                                                          | 8Gi                                                                                                                 |
| `statefulset.container.resources.limits.cpu`                | The maximum cpu the Nexus repository pod may get.                                                                                                                                                                                                                                                                                                                                | 4                                                                                                                   |
| `statefulset.container.resources.limits.memory`             | The maximum memory the Nexus repository pod may get.                                                                                                                                                                                                                                                                                                                             | 8Gi                                                                                                                 |
| `statefulset.container.containerPort`                       | The Nexus Repository container's HTTP port                                                                                                                                                                                                                                                                                                                                       | 8081                                                                                                                |
| `statefulset.container.pullPolicy`                          | The Nexus Repository docker image pull policy                                                                                                                                                                                                                                                                                                                                    | IfNotPresent                                                                                                        |
| `statefulset.container.terminationGracePeriod`              | The time given for the pod to gracefully shut down                                                                                                                                                                                                                                                                                                                               | 120 seconds                                                                                                         |
| `statefulset.container.env.nexusDBName`                     | The name of the PostgreSQL database to use.                                                                                                                                                                                                                                                                                                                                      | nexus                                                                                                               |
| `statefulset.container.env.nexusDBPort`                     | The database port of the PostgreSQL database to use.                                                                                                                                                                                                                                                                                                                             | 5432                                                                                                                |
| `statefulset.container.env.install4jAddVmParams`            | Xmx and Xms settings for JVM                                                                                                                                                                                                                                                                                                                                                     | -Xms2703m -Xmx2703m                                                                                                 |
| `statefulset.container.env.jdbcUrlParams`                   | Additional parameters to append to the database url. Expected format is  `"?foo=bar&baz=foo"`                                                                                                                                                                                                                                                                                    | null                                                                                                                |
| `statefulset.container.additionalEnv`                       | Additional environment variables for the Nexus Repository container. You can also use this setting to override a default env variable by specifying the same key/name as the default env variable you wish override. Specify this as a block of name and value pairs (e.g., "<br/>additionalEnv:<br/>- name: foo<br/> value: bar<br/>- name: foo2<br/> value: bar2")             | null                                                                                                                |
| `statefulset.requestLogContainer.image.repository`          | Image registry URL for a container which tails Nexus Repository's request log                                                                                                                                                                                                                                                                                                    | busybox                                                                                                             |
| `statefulset.requestLogContainer.image.tag`                 | Image tag for a container which tails Nexus Repository's request log                                                                                                                                                                                                                                                                                                             | 1.33.1                                                                                                              |
| `statefulset.requestLogContainer.resources.requests.cpu`    | The minimum cpu the request log container can request                                                                                                                                                                                                                                                                                                                            | 0.1                                                                                                                 |
| `statefulset.requestLogContainer.resources.requests.memory` | The minimum memory the request log container can request                                                                                                                                                                                                                                                                                                                         | 256Mi                                                                                                               |
| `statefulset.requestLogContainer.resources.limits.cpu`      | The maximum cpu the request log container may get.                                                                                                                                                                                                                                                                                                                               | 0.2                                                                                                                 |
| `statefulset.requestLogContainer.resources.limits.memory`   | The maximum memory the request log container may get.                                                                                                                                                                                                                                                                                                                            | 512Mi                                                                                                               |
| `statefulset.auditLogContainer.image.repository`            | Image registry URL for a container which tails Nexus Repository's audit log                                                                                                                                                                                                                                                                                                      | busybox                                                                                                             |
| `statefulset.auditLogContainer.image.tag`                   | Image tagfor a container which tails Nexus Repository's audit log                                                                                                                                                                                                                                                                                                                | 1.33.1                                                                                                              |
| `statefulset.auditLogContainer.resources.requests.cpu`      | The minimum cpu the audit log container can request                                                                                                                                                                                                                                                                                                                              | 0.1                                                                                                                 |
| `statefulset.auditLogContainer.resources.requests.memory`   | The minimum memory the audit log container can request                                                                                                                                                                                                                                                                                                                           | 256Mi                                                                                                               |
| `statefulset.auditLogContainer.resources.limits.cpu`        | The maximum cpu the audit log container may get.                                                                                                                                                                                                                                                                                                                                 | 0.2                                                                                                                 |
| `statefulset.auditLogContainer.resources.limits.memory`     | The maximum memory the reauditquest log container may get.                                                                                                                                                                                                                                                                                                                       | 512Mi                                                                                                               |
| `statefulset.taskLogContainer.image.repository`             | Image registry URL for a container which aggregates and tails Nexus Repository's task log                                                                                                                                                                                                                                                                                        | busybox                                                                                                             |
| `statefulset.taskLogContainer.image.tag`                    | Image tag for a container which aggregates and tails Nexus Repository's task log                                                                                                                                                                                                                                                                                                 | 1.33.1                                                                                                              |
| `statefulset.taskLogContainer.resources.requests.cpu`       | The minimum cpu the task log container can request                                                                                                                                                                                                                                                                                                                               | 0.1                                                                                                                 |
| `statefulset.taskLogContainer.resources.requests.memory`    | The minimum memory the task log container can request                                                                                                                                                                                                                                                                                                                            | 256Mi                                                                                                               |
| `statefulset.taskLogContainer.resources.limits.cpu`         | The maximum cpu the task log container may get.                                                                                                                                                                                                                                                                                                                                  | 0.2                                                                                                                 |
| `statefulset.taskLogContainer.resources.limits.memory`      | The maximum memory the task log container may get.                                                                                                                                                                                                                                                                                                                               | 512Mi                                                                                                               |
| `statefulset.startupProbe.initialDelaySeconds`              | StartupProbe initial delay                                                                                                                                                                                                                                                                                                                                                       | 0                                                                                                                   |
| `statefulset.startupProbe.periodSeconds`                    | Seconds between polls                                                                                                                                                                                                                                                                                                                                                            | 10                                                                                                                  |
| `statefulset.startupProbe.failureThreshold`                 | Number of attempts before failure                                                                                                                                                                                                                                                                                                                                                | 180                                                                                                                 |
| `statefulset.startupProbe.timeoutSeconds`                   | Time in seconds after liveness probe times out                                                                                                                                                                                                                                                                                                                                   | 1                                                                                                                   |
| `statefulset.startupProbe.path`                             | Path for StartupProbe                                                                                                                                                                                                                                                                                                                                                            | /                                                                                                                   |
| `statefulset.livenessProbe.initialDelaySeconds`             | LivenessProbe initial delay                                                                                                                                                                                                                                                                                                                                                      | 0                                                                                                                   |
| `statefulset.livenessProbe.periodSeconds`                   | Seconds between polls                                                                                                                                                                                                                                                                                                                                                            | 60                                                                                                                  |
| `statefulset.livenessProbe.failureThreshold`                | Number of attempts before failure                                                                                                                                                                                                                                                                                                                                                | 6                                                                                                                   |
| `statefulset.livenessProbe.timeoutSeconds`                  | Time in seconds after liveness probe times out                                                                                                                                                                                                                                                                                                                                   | 1                                                                                                                   |
| `statefulset.livenessProbe.path`                            | Path for LivenessProbe                                                                                                                                                                                                                                                                                                                                                           | /                                                                                                                   |
| `statefulset.readinessProbe.initialDelaySeconds`            | ReadinessProbe initial delay                                                                                                                                                                                                                                                                                                                                                     | 0                                                                                                                   |
| `statefulset.readinessProbe.periodSeconds`                  | Seconds between polls                                                                                                                                                                                                                                                                                                                                                            | 60                                                                                                                  |
| `statefulset.readinessProbe.failureThreshold`               | Number of attempts before failure                                                                                                                                                                                                                                                                                                                                                | 6                                                                                                                   |
| `statefulset.readinessProbe.timeoutSeconds`                 | Time in seconds after readiness probe times out                                                                                                                                                                                                                                                                                                                                  | 1                                                                                                                   |
| `statefulset.readinessProbe.path`                           | Path for ReadinessProbe                                                                                                                                                                                                                                                                                                                                                          | /                                                                                                                   |
| `statefulset.imagePullSecrets`                              | The pull secret for private image registries                                                                                                                                                                                                                                                                                                                                     | `{}`                                                                                                                |
| `ingress.enabled`                                           | Whether or not to create the Ingress                                                                                                                                                                                                                                                                                                                                             | false                                                                                                               |
| `ingress.host`                                              | Ingress host                                                                                                                                                                                                                                                                                                                                                                     | `null`                                                                                                              |
| `ingress.hostPath`                                          | Path for ingress rules.                                                                                                                                                                                                                                                                                                                                                          | `/`                                                                                                                 |
| `ingress.dockerSubdomain`                                   | Whether or not to add rules for docker subdomains                                                                                                                                                                                                                                                                                                                                | `false`                                                                                                             |
| `ingress.defaultRule`                                       | Whether or not to add a default rule for the Nexus Repository Ingress which forwards traffic to a Service object                                                                                                                                                                                                                                                                 | `false`                                                                                                             |
| `ingress.additionalRules`                                   | Additional rules to add to the ingress                                                                                                                                                                                                                                                                                                                                           | `null`                                                                                                              |
| `ingress.incressClassName`                                  | The ingress class name e.g., nginx, alb etc.                                                                                                                                                                                                                                                                                                                                     | `null`                                                                                                              |
| `ingress.tls.secretName`                                    | The name of a Secret object in which to store the TLS secret for ingress                                                                                                                                                                                                                                                                                                         | `null`                                                                                                              |
| `ingress.tls.hosts`                                         | A list of TLS hosts                                                                                                                                                                                                                                                                                                                                                              | `null`                                                                                                              |
| `ingress.annotations`                                       | Annotations for the Ingress object                                                                                                                                                                                                                                                                                                                                               | `nil`                                                                                                               |
| `storageClass.enabled`                                      | Set to true if you'd like to create your own storage class for persistent volumes and persistent volume claims                                                                                                                                                                                                                                                                   | `false`                                                                                                             |
| `storageClass.name`                                         | The name of a storage class object to create                                                                                                                                                                                                                                                                                                                                     | `nexus-storage`                                                                                                     |
| `storageClass.provisioner`                                  | The name of a storage class provisioner                                                                                                                                                                                                                                                                                                                                          | `provisionerName`                                                                                                   |
| `storageClass.volumeBindingMode`                            | The volume binding mode for the storage class                                                                                                                                                                                                                                                                                                                                    | `WaitForFirstConsumer`                                                                                              |
| `storageClass.reclaimPolicy`                                | The reclaim policy for any volumes which use this storage class                                                                                                                                                                                                                                                                                                                  | `Retain`                                                                                                            |
| `storageClass.parameters`                                   | Volume parameters for the storage class                                                                                                                                                                                                                                                                                                                                          | `nil`                                                                                                               |
| `storageClass.allowVolumeExpansion`                         | Whether or not to allow more storage to be claimed by a Persistent Volume Claim                                                                                                                                                                                                                                                                                                  | `false`                                                                                                             |
| `storageClass.mountOptions`                                 | Mounting options for volumes using the storage class                                                                                                                                                                                                                                                                                                                             | `nil`                                                                                                               |
| `pvc.accessMode`                                            | The persistent volume claim access mode                                                                                                                                                                                                                                                                                                                                          | ReadWriteOnce                                                                                                       |
| `pvc.storage`                                               | The volume size to request for storing Nexus logs                                                                                                                                                                                                                                                                                                                                | 2Gi                                                                                                                 |
| `pvc.existingClaim`                       | The name of an existing Persistent Volume Claim to use for Nexus Repository data. **Important: This is only for single-instance deployments to provide resiliency. Do not use for high availability deployments.** | `null`               | 
| `pvc.volumeClaimTemplate.enabled`                           | You should set this property to true for cloud deployments in order to use dynamic volume provisioning to reserve volumes for Nexus Repository's logs. For on-premises deployment use [Local Persistence Volumen Static Provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) to automatically create persistent volumes for pre-attached disks. | `false`                                                                                                             |
| `service.annotations`                                       | Common annotations for all Service objects (nexus, docker-registries, nexus-headless)                                                                                                                                                                                                                                                                                            | `{}`                                                                                                                |
| `service.nexus.enabled`                                     | Whether or not to create the Service object                                                                                                                                                                                                                                                                                                                                      | `false`                                                                                                             |
| `service.nexus.type`                                        | The type of the Kubernetes Service                                                                                                                                                                                                                                                                                                                                               | "NodePort"                                                                                                          |
| `service.nexus.protocol`                                    | The protocol                                                                                                                                                                                                                                                                                                                                                                     | TCP                                                                                                                 |
| `service.nexus.port`                                        | The port to listen for incoming requests                                                                                                                                                                                                                                                                                                                                         | `80`                                                                                                                |
| `service.headless.annotations`                              | Annotations for the headless service object                                                                                                                                                                                                                                                                                                                                      | `{}`                                                                                                                |
| `service.headless.publishNotReadyAddresses`                 | Whether or not the service to be discoverable even before the corresponding endpoints are ready                                                                                                                                                                                                                                                                                  | `true`                                                                                                              |
| `service.nexus.targetPort`                                  | The port to forward requests to                                                                                                                                                                                                                                                                                                                                                  | `8081`                                                                                                              |
 | `externalsecrets.enabled`                                   | Set this to true if https://external-secrets.io/latest/ is installed in your Kubernetes cluster and you would like to use it for providing needed secrets to your Nexus Repository pods                                                                                                                                                                                          |                                                                                                                     |
 | `externalsecrets.secretstore.spec`                          | Set this to the SecretStore configuration for your external secret store. See https://external-secrets.io/latest/ for examples.                                                                                                                                                                                                                                                  |                                                                                                                     |
 | `externalsecrets.secrets.database.providerSecretName`       | Set this to the name of the secret containing your database credentials in your external secret store. E.g. if using AWS, this should be the name of the secret in your AWS Secrets Manager. If using Azure, this should be the name of the secret in your Azure Key Vault                                                                                                       |                                                                                                                     |
 | `externalsecrets.secrets.database.dbUserKey`                | Set this to the name of the key in the secret which contains your database username.                                                                                                                                                                                                                                                                                             |                                                                                                                     |
 | `externalsecrets.secrets.database.dbPasswordKey`            | Set this to the name of the key in the secret which contains your database password.                                                                                                                                                                                                                                                                                             |                                                                                                                     |
 | `externalsecrets.secrets.database.dbHostKey`                | Set this to the name of the key in the secret which contains your database host.                                                                                                                                                                                                                                                                                                 |                                                                                                                     |
 | `externalsecrets.secrets.admin.providerSecretName`          | Set this to the name of the secret containing your Nexus Repository admin password in your external secret store. E.g. if using AWS, this should be the name of the secret in your AWS Secrets Manager. If using Azure, this should be the name of the secret in your Azure Key Vault                                                                                            |                                                                                                                     |
 | `externalsecrets.secrets.admin.adminPasswordKey`            | Set this to the name of the key in the secret which contains your which contains your initial Nexus Repository admin password.                                                                                                                                                                                                                                                   |                                                                                                                     |
 | `externalsecrets.secrets.license.providerSecretName`        | Set this to the name of the secret containing your Nexus Repository license in your external secret store. E.g. if using AWS, this should be the name of the secret in your AWS Secrets Manager. If using Azure, this should be the name of the secret in your Azure Key Vault                                                                                                   |                                                                                                                     |
| `secret.secretProviderClass`                                | The secret provider class for Kubernetes secret store object. See [secret.yaml](templates%2Fsecret.yaml). Set this when using AWS Secret Manager or Azure Key Vault                                                                                                                                                                                                              | secretProviderClass                                                                                                 |
| `secret.provider`                                           | The provider (e.g. azure, aws etc) for Kubernetes secret store object. Set this when using AWS Secret Manager or Azure Key Vault                                                                                                                                                                                                                                                 | provider                                                                                                            |
| `secret.dbSecret.enabled`                                   | Whether or not to install [database-secret.yaml](templates%2Fdatabase-secret.yaml). Set this to `false` when using AWS Secret Manager or Azure Key Vault                                                                                                                                                                                                                         | `false`                                                                                                             |
| `secret.db.user`                                            | The key for secret in AWS Secret manager or Azure Key Vault which contains the database user name. Otherwise if `secret.dbSecret.enabled` is true, set this to the database user name.                                                                                                                                                                                           | nxrm_db_user                                                                                                        |
| `secret.db.user-alias`                                      | Applicable to AWS Secret Manager only. An alias to use for the database user secret retrieved from AWS Secret manager.                                                                                                                                                                                                                                                           | nxrm_db_user_alias                                                                                                  |
| `secret.db.password`                                        | The key for secret in AWS Secret manager or Azure Key Vault which contains the database password. Otherwise if `secret.dbSecret.enabled` is true, set this to the database password.                                                                                                                                                                                             | nxrm_db_password                                                                                                    |
| `secret.db.password-alias`                                  | Applicable to AWS Secret Manager only. An alias to use for the database password secret retrieved from AWS Secret manager.                                                                                                                                                                                                                                                       | nxrm_db_password_alias                                                                                              |
| `secret.db.host`                                            | The key for secret in AWS Secret manager or Azure Key Vault which contains the database host URL. Otherwise if `secret.dbSecret.enabled` is true, set this to the database host URL.                                                                                                                                                                                             | nxrm_db_host                                                                                                        |
| `secret.db.host-alias`                                      | Applicable to AWS Secret Manager only. An alias to use for the database host secret retrieved from AWS Secret manager.                                                                                                                                                                                                                                                           | nxrm_db_host_alias                                                                                                  |
| `secret.nexusAdminSecret.enabled`                           | Whether or not to install [nexus-admin-secret.yaml](templates%2Fnexus-admin-secret.yaml). Set this to `false` when using AWS Secret Manager or Azure Key Vault.                                                                                                                                                                                                                  | `false`                                                                                                             |
| `secret.nexusAdminSecret.adminPassword`                     | When `secret.nexusAdminSecret.enabled` is true, set this to the initial admin password for Nexus Repository.  Otherwise ignore.                                                                                                                                                                                                                                                  | yourinitialnexuspassword                                                                                            |
| `secret.nexusAdmin.name`                                    | The key for secret in AWS Secret manager or Azure Key Vault which contains the initial Nexus Repository admin password. Otherwise if `secret.nexusAdminSecret.enabled` is true, then set this to the name for [nexus-admin-secret.yaml](templates%2Fnexus-admin-secret.yaml)                                                                                                     | `nexusAdminPassword`                                                                                                |
| `secret.nexusAdmin.alias`                                   | Applicable to AWS Secret Manager only. An alias to use for the initial Nexus Repository admin password secret retrieved from AWS Secret manager.                                                                                                                                                                                                                                 | `admin-nxrm-password-alias`                                                                                         |
| `secret.license.name`                                       | The name for [license-config-mapping.yaml](templates%2Flicense-config-mapping.yaml) for storing Nexus Repository license. This is an alternative way of specifying your Nexus Repository Pro license. Use this option when not using Azure Key Vault or AWS Secret Manager                                                                                                       | nexus-repo-license.lic                                                                                              |
| `secret.license.licenseSecret.enabled`                      | Whether or not to install [license-config-mapping.yaml](templates%2Flicense-config-mapping.yaml)                                                                                                                                                                                                                                                                                 | `false`                                                                                                             |
| `secret.license.licenseSecret.file`                         | Name of the nexus file with path. Set this if you're not using AWS Secret Manager or Azure Key Vault to store your Nexus Repository Pro license.                                                                                                                                                                                                                                 | your_license_file_with_full_path                                                                                    |
| `secret.license.licenseSecret.fileContentsBase64`           | A base64 representation of your Nexus Repository Pro license. Set this if you're not using AWS Secret Manager or Azure Key Vault to store your Nexus Repository Pro license.                                                                                                                                                                                                     | your_license_file_contents_in_base_64                                                                               |
| `secret.license.licenseSecret.mountPath`                    | The path where your Nexus Repository Pro license is mounted in the Nexus Repository container                                                                                                                                                                                                                                                                                    | /var/nexus-repo-license                                                                                             |
| `secret.nexusSecret.name`                                   | The name of the [nexus-secret-mapping.yaml](templates%2Fnexus-secret-mapping.yaml) secret for storing Nexus Repository encryption secrets.                                                                                                                                                                                                                                       | nexus-secret.json                                                                                                   |
| `secret.nexusSecret.enabled`                                | Whether or not to install [nexus-secret-mapping.yaml](templates%2Fnexus-secret-mapping.yaml) secret                                                                                                                                                                                                                                                                              | `false`                                                                                                             |
| `secret.nexusSecret.secretKeyfile`                          | The name of a file which contains a JSON document of keys to be used for encryption                                                                                                                                                                                                                                                                                              | secretfileName                                                                                                      |
| `secret.nexusSecret.mountPath`                              | The path where your JSON document of keys is mounted in the Nexus Repository container                                                                                                                                                                                                                                                                                           | /var/nexus-repo-secrets                                                                                             |
| `secret.azure.userAssignedIdentityID`                       | A managed identity or service principal that has `secrets management` access to the key vault. Only applicable if this chart is installed on Azure and you've stored database credentials, Nexus Repository initial admin password and your Nexus Repository Pro license in Azure Key Vault.                                                                                     | userAssignedIdentityID                                                                                              |
| `secret.azure.tenantId`                                     | Your Azure tenant id. Only applicable if this chart is installed on Azure and you've stored database credentials, Nexus Repository initial admin password and your Nexus Repository Pro license in Azure Key Vault.                                                                                                                                                              | azureTenantId                                                                                                       |
| `secret.azure.keyvaultName`                                 | The name of the Azure Key vault containing database credentials and license. Only applicable if this chart is installed on Azure and you've stored database credentials, Nexus Repository initial admin password and your Nexus Repository Pro license in Azure Key Vault.                                                                                                       | yourazurekeyvault                                                                                                   |
| `secret.azure.useVMManagedIdentity`                         | Whether or not to use an Azure virtual machine managed identity. Only applicable if this chart is installed on Azure and you've stored database credentials, Nexus Repository initial admin password and your Nexus Repository Pro license in Azure Key Vault.                                                                                                                   | `true`                                                                                                              |
| `secret.azure.usePodIdentity`                               | Whether or not to use pod identity. Only applicable if this chart is installed on Azure and you've stored database credentials, Nexus Repository initial admin password and your Nexus Repository Pro license in Azure Key Vault.                                                                                                                                                | `false`                                                                                                             |
| `secret.azure.nexusSecret.enabled`                          | Whether the nexus secrets file should be mounted from Azure key vault                                                                                                                                                                                                                                                                                                            | `false`                                                                                                             | 
| `secret.aws.license.arn`                                    | The Amazon Resource Name for your Nexus Repository Pro license secret stored in AWS Secrets Manager. Only applicable if this chart is installed on AWS and you've stored your Nexus Repository Pro license in AWS Secrets Manager.                                                                                                                                               | `arn:aws:secretsmanager:us-east-1:000000000000:secret:nxrm-nexus-license`                                           |
| `secret.aws.adminpassword.arn`                              | The Amazon Resource Name for the Nexus Repository initial admin secret stored in AWS Secrets Manager. Only applicable if this chart is installed on AWS and you've stored your Nexus Repository initial admin password in AWS Secrets Manager.                                                                                                                                   | `arn:aws:secretsmanager:us-east-1:000000000000:secret:admin-nxrm-password`                                          |
| `secret.aws.rds.arn`                                        | The Amazon Resource Name for the database secrets stored in AWS Secrets Manager. Only applicable if this chart is installed on AWS and you've stored your database credentials in AWS Secrets Manager.                                                                                                                                                                           | `arn: arn:aws:secretsmanager:us-east-1:000000000000:secret:nxrmrds-cred-nexus`                                      |
| `secret.aws.nexusSecret.enabled`                            | Whether the nexus secrets file should be mounted from AWS secrets manager                                                                                                                                                                                                                                                                                                        | `false`                                                                                                             | 
| `secret.aws.nexusSecret.arn`                                | The Amazon Resource Name for the nexus secret JSON secret stored in AWS secrets manager                                                                                                                                                                                                                                                                                          | `arn:aws:secretsmanager:us-east-1:000000000000:secret:nxrm-nexus-secrets-file`                                      |                                                                              |
| `nexus.securityContext.runAsUser`                           | The user to run the Nexus Repository pod as                                                                                                                                                                                                                                                                                                                                      | `200`                                                                                                               |
| `nexus.properties.override`                                 | Whether or not to mount config map which contains overrides for default nexus properties                                                                                                                                                                                                                                                                                         | `false`                                                                                                             |
| `nexus.properties.data`                                     | A list of key and values to override default nexus.properties                                                                                                                                                                                                                                                                                                                    | `null`                                                                                                              |
| `nexus.extraLabels`                                         | Extra labels to apply to all objects                                                                                                                                                                                                                                                                                                                                             | `{}`                                                                                                                |
| `nexus.extraSelectorLabels`                                 | Extra selector labels to apply to all services and Nexus Repository pods. See [services.yaml](templates%2Fservices.yaml) and [statefulset.yaml](templates%2Fstatefulset.yaml)                                                                                                                                                                                                    | `{}`                                                                                                                |
| `nexus.docker.enabled`                                      | Whether or not to create a Kubernetes Service object for a given docker repository within Nexus Repository                                                                                                                                                                                                                                                                       | `false`                                                                                                             |
| `nexus.docker.type`                                         | The type of the Kubernetes Service                                                                                                                                                                                                                                                                                                                                               | `NodePort`                                                                                                          |
| `nexus.docker.protocol`                                     | The protocol                                                                                                                                                                                                                                                                                                                                                                     | TCP                                                                                                                 |
| `nexus.docker.registries`                                   | The docker registries to create ingresses and services for. See the  [ingress.yaml](templates%2Fingress.yaml) and  [services.yaml](templates%2Fservices.yaml) for how it's used                                                                                                                                                                                                  | `null`                                                                                                              |
| `config.enabled`                                            | Enable and mount a config map containing arbitrary data i.e. key value pairs                                                                                                                                                                                                                                                                                                     | `false`                                                                                                             |
| `config.data`                                               | The data for the config map                                                                                                                                                                                                                                                                                                                                                      | `{}`                                                                                                                |
| `config.mountPath`                                          | The file path to mount the config map into. Each key value pair in the config map is put on a separate line in the file                                                                                                                                                                                                                                                          | `/sonatype-nexus-conf`                                                                                              |
