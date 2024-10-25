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

# Overview
You can use the sample YAML files in this section to help set up the YAMLs you will need for a High-Availability (HA) Nexus Repository deployment. 
Ensure you have filled out the YAML files with appropriate information for your deployment.

> **Note** The YAML files in this section are just examples and cannot be copy-pasted and used as-is. You must fill them out with the appropriate information for your deployment to be able to use them.

# YAML Order
1. [Namespaces YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-namespaces.yaml)
2. [Logback Tasklogfile Override YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-logback-tasklogfile-override.yaml)
3. [Services YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-services.yaml)
4. [Docker Services YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-docker-service.yaml)
5. [StatefulSet YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-statefulset.yaml)
6. [Ingress YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-ingress.yaml)
7. [Service Account YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-service-accounts.yaml)
8. [Storage Class YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-ha-storage-class.yaml)
9. [Helm chart values example - ESO enabled YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-values-eso-enabled.yaml)
10. [Helm chart values example - ESO disabled YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/gcp-values-eso-disabled.yaml)
>**Note** 
>* The resources created by these YAMLs are not in the default namespace. 
>* The sample YAMLs are set up to disable the default blob stores and repositories on all instances.

# Additional Resources

Files that can be used as a source to put into Google Secret Manager secrets:

You can use the following files as a source to put into Google Secret Manager secrets (upload files as secrets):
1. [Database secret](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/dbSecrets.json)
2. [Nexus password secret](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-gcp-ha-yamls/adminSecrets.json)
>**Note** 
>* For the license secret you should encode the license file using base64 encoder. Then put the encoded license file directly as "nxrmLicense" secret value.
>* Google Secret Manager secret names used in the sample YAMLS are "nxrmDbSecret", "nxrmAdminSecret", and "nxrmLicense". 