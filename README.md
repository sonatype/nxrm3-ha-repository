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

# Nexus Repository 3 High Availability (HA) Helm and Sample YAML Repository
This repository contains resources for those in our **Nexus Repository 3 High Availability**. 
Please refer to the documentation provided by your Customer Success Engineer for instructions on how to use these files.

## HA Prerequisites and System Requirements

Along with the HA-specific requirements listed below, you should also ensure that you meet our [normal Nexus Repository system requirements](https://help.sonatype.com/repomanager3/product-information/system-requirements).

HA requires the following:
* A Nexus Repository 3 Pro license
* An external PostgreSQL database using Postgres 13 or later; size your database appropriately based on your request traffic and desired number of nodes
* At least 2 Nexus Repository instances
    * All Nexus Repository instances must be using the same Nexus Repository 3 Pro version, and it must be version 3.45.1 or later
    * All Nexus Repository instances must have identical configuration in their $data-dir/etc/nexus.properties files
* A load balancer (e.g., HAProxy, NGINX, Apache HTTP, or AWS ELB)
* A blob store location for storing components that can be commonly accessed by all active nodes
* Connectivity between Nexus Repository, the database, and blob store
* All architecture must be in one region (if deploying to cloud) or data center (if deploying on-premises)
* A physical disk for storing Nexus Repository logs and configuration settings used for generating the support zip

If the Nexus Repository deployment will contain more than one Docker repository,  you must use one of the following:
* An external load balancer (e.g., NGINX) as a [reverse proxy](https://help.sonatype.com/display/NXRM3M/Docker+Repository+Reverse+Proxy+Strategies) instead of the provided ingress for Docker YAML 
* A [Docker Subdomain Connector](https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/docker-registry/docker-subdomain-connector) with external DNS to route traffic to each Docker subdomain


# Pre-requisites

### Storage
The default configuration uses an emptyDir volume for storing Nexus Repository logs. However, this is only for demonstration purposes. For production, we strongly recommend that
you configure dynamic provisioning of persistent storage or attach dedicated local disks based on your deployment environment as explained below.

#### Cloud deployments (AWS/Azure)
* Ensure the appropriate Container Storage Interface (CSI) driver(s) are installed on the Kubernetes cluster on your chosen cloud deployment. Please refer to AWS EKS/Azure AKS documentation for details on configuring CSI drivers.

#### On premise deployments
1. Attach separate disks (i.e. separate from the root disk) to your worker nodes.
2. Install the Local Persistence Volume Static Provisioner. Please refer to [Local Persistence Volume Static Provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) documentation.
3. Use the Local Persistence Volume Static Provisioner to automatically create persistent volumes for your chosen storage class name as documented [here](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)

#### Configuring for dynamic persistent volume provisioning
* Set the `storageClass.name` parameter to a storage class name. This could be one of the default storage classes automatically created in your managed Kubernetes cluster on your chosen cloud (e.g., if you're using AWS EKS) or one that you would like to create.
  * If you would like to create a dedicated storage class (i.e., you don't want to use the default), then in addition to specifying a value for `storageClass.name`, you must also set `storageClass.enabled` parameter to `true`.
  * Set the `nexusData.volumeClaimTemplate.enabled` parameter to true.
  * Set the `storageClass.provisioner` e.g. for AWS EBS, ebs.csi.aws.com

## Format Limitations
HA supports all formats that PostgreSQL supports.


## Deployment Configuration

### AWS
* Set `aws.enabled` to `true`

#### Storage:
  * Set `pvc.volumeClaimTemplate.enabled` to `true`
  * Set `storageClass.name` to the name of the storage class to use for dynamic volume provisioning.
    * If you're running on Cloud and would like to use an in-built storage class, set this to the name of that storage class E.g. for AWS `gp2`
    * Alternatively, if you would like to create your own storage class then:
      * Specify values for the [storageclass.yaml](nxrm-ha-helm%2Ftemplates%2Fstorageclass.yaml) file
      * Enable it by setting `storageClass.enabled` to true 

#### Secrets
AWS Secret Manager is disabled by default. If you would like to store your database secrets and license in AWS Secrets Manager, do as follows:
* Set `aws.secretmanager.enabled` to `true`
  * Database credentials:
    * Store database credentials (i.e. host, user and password) in AWS secret manager
    * In your values.yaml,
      * Set the keys and aliases to use for getting the database credentials from secrets manager:  
          `db:
             user: username
             userAlias: nxrm-db-user
             password: password
             passwordAlias: nxrm-db-password
             host: host
             hostAlias: nxrm-db-host`
        * Update the `secret.aws.rds.arn` to your Secret Manager ARN containing database credentials
  * Initial Nexus Repository Admin Password
    * Store initial Nexus repository Admin password in AWS Secrets Manager 
    * Set the `secret.nexusAdmin.name` to the key you used in secrets manager
    * Set the `secret.nexusAdmin.alias` to the alias you would like the helm chart to use
    * Update the `secret.aws.adminpassword.arn` to your Secret Manager ARN containing initial admin password
  * License:
    * Store your Nexus Repository Pro license in AWS Secrets Manager
    * Update the `secret.aws.license.arn` to your Secret Manager ARN containing your Nexus Repository Pro license
 

### Azure
* Set `azure.enabled` to `true`

#### Storage:
* Set `pvc.volumeClaimTemplate.enabled` to `true`
* Set `storageClass.name` to the name of the storage class to use for dynamic volume provisioning.
  * If you're running on Cloud and would like to use an in-built storage class, set this to the name of that storage class E.g. for Azure `managed-csi`
  * Alternatively, if you would like to create your own storage class then:
    * Specify values for the [storageclass.yaml](nxrm-ha-helm%2Ftemplates%2Fstorageclass.yaml) file
    * Enable it by setting `storageClass.enabled` to true

#### Secrets
Azure Key Vault is disabled by default. If you would like to store your database secrets and license in Azure Key Vault, do as follows:
* Set `azure.keyvault.enabled` to `true`
  * Database credentials:
    * Store database credentials (i.e. host, user and password) in Azure Key Vault
    * In your values.yaml,
      * Set the keys to use for getting the database credentials from Azure Key Vault:  
        `db:
          user: username
          password: password
          host: host`
      * Set the parameters nested in `secret.azure` accordingly. 
  * Initial Nexus Repository Admin Password
    * Store initial Nexus repository Admin password in Azure Key Vault
    * Set the `secret.nexusAdmin.name` to the key you used in Azure Key Vault
  * License:
    * Store your Nexus Repository Pro license in Azure Key Vault
    * Set the `secret.license.name` to Azure Key Vault secret containing your Nexus Repository Pro license

### On-premises
The chart doesn't install any cloud specific resources when `aws.enabled`  and `azure.enabled` are false.

#### Storage:
* Attach dedicated disks to your Kubernetes worker nodes
* Install the Local Persistence Volume Static Provisioner and configure it to automatically create persistent volumes for your chosen storage class name as documented [here](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)

#### Secrets
* Database credentials:
  * Set `secret.dbSecret.enabled` to `true` to enable [database-secret.yaml](nxrm-ha-helm%2Ftemplates%2Fdatabase-secret.yaml) for storing database secrets.
  * Specify values for [database-secret.yaml](nxrm-ha-helm%2Ftemplates%2Fdatabase-secret.yaml)
* Initial Nexus Repository Admin Password
  * Set `secret.nexusAdminSecret.enabled` to `true` to enable [nexus-admin-secret.yaml](nxrm-ha-helm%2Ftemplates%2Fnexus-admin-secret.yaml) for storing initial Nexus Repository admin password secret.
  * Specify values for [nexus-admin-secret.yaml](nxrm-ha-helm%2Ftemplates%2Fnexus-admin-secret.yaml)
* License:
  * Set the `secret.license.licenseSecret.enabled` to true enable [license-config-mapping.yaml](nxrm-ha-helm%2Ftemplates%2Flicense-config-mapping.yaml) for storing your Nexus Repository Pro license
  * Specify values for [license-config-mapping.yaml](nxrm-ha-helm%2Ftemplates%2Flicense-config-mapping.yaml)