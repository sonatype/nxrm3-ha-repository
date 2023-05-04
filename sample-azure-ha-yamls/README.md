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
1. [Namespaces YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-namespaces.yaml)
2. [Secrets YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-secret.yaml)
3. [Logback Tasklogfile Override YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-logback-tasklogfile-override.yaml)
4. [Services YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-services.yaml)
5. [Ingress for Docker YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-ingress-for-docker-connector.yaml)
6. [Docker Services YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-docker-service.yaml)
7. [StatefulSet YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-statefulset.yaml)
8. [Ingress YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-azure-ha-yamls/azure-ha-ingress.yaml)

>**Note** 
>* The resources created by these YAMLs are not in the default namespace. 
>* The sample YAMLs are set up to disable the default blob stores and repositories on all instances.
