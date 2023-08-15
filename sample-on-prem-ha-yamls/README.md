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

## Storage

### Local storage

By default, the [onprem-ha-statefulset.yaml](onprem-ha-statefulset.yaml) uses local storage. You'll need to create directories
on each node in your Kubernetes cluster for storing nexus repository runtime (logs, config dump etc) data.

* The number of directories you create should be driven by the number of Sonatype Nexus Repository instances (i.e., replicas) you wish to run in your Kubernetes cluster.
    Presently, there are five persistence volumes in the [onprem-ha-nexus-data-local-persistent-volume.yaml](onprem-ha-nexus-data-local-persistent-volume.yaml) file.
    Thus, you need to create five directories on each node as shown below:
    ```
    mkdir -p /var/nexus-repo-mgr-work-dir/work1
    mkdir -p /var/nexus-repo-mgr-work-dir/work2
    mkdir -p /var/nexus-repo-mgr-work-dir/work3
    mkdir -p /var/nexus-repo-mgr-work-dir/work4
    mkdir -p /var/nexus-repo-mgr-work-dir/work5
    ```

* You must chown all the directories you create to ```200:200``` as follows: ```chown -R 200:200 /var/nexus-repo-mgr-work-dir/ ```

# YAML Order

1. [Namespaces YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-namespaces.yaml)
2. [License Configuration Mapping](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-license-config-mapping.yaml)
3. [NFS Persistent Volume](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-blobs-nfs-persistent-volume.yaml)
4. [NFS Persistent Volume Claim](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-blobs-nfs-persistent-volume-claim.yaml)
5. [Storage Class YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-storage-class.yaml)
6. [Local Persistent Volume](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-nexus-data-local-persistent-volume.yaml)
7. [StatefulSet YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-statefulset.yaml)
8. [Services YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-services.yaml)
9. [Ingress YAML](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-ingress.yaml)
10.[Docker Ingress YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-docker-ingress.yaml)
11.[Docker Service YAML (Optional)](https://github.com/sonatype/nxrm3-ha-repository/blob/main/sample-on-prem-ha-yamls/onprem-ha-docker-service.yaml)

> **Note** The resources created by these YAMLs are not in the default namespace.

