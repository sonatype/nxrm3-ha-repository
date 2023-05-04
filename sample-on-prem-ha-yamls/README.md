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

1. [Namespaces YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-namespaces.yaml)
2. [Local Workdir Configmap](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-nexus-data-local-workdir-configmap.yaml)
3. [Local Workdir Daemonset](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-nexus-data-local-workdir-daemonset.yaml)
4. [License Configuration Mapping](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-license-config-mapping.yaml)
5. [NFS Persistent Volume](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-blobs-nfs-persistent-volume.yaml)
6. [NFS Persistent Volume Claim](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-blobs-nfs-persistent-volume-claim.yaml)
7. [Storage Class YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-storage-class.yaml)
8. [Local Persistent Volume](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-nexus-data-local-persistent-volume.yaml)
9. [StatefulSet YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-statefulset.yaml)
10. [Services YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-services.yaml)
11. [Ingress YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-ingress.yaml)
12. [Docker Ingress YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-docker-ingress.yaml)
13. [Docker Service YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-docker-service.yaml)

> **Note** The resources created by these YAMLs are not in the default namespace.

