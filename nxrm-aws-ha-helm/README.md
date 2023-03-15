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

# Helm Chart for a High-Availability Nexus Repository Deployment in AWS

This Helm chart configures the Kubernetes resources that are needed for a high-availability (HA) Nexus Repository deployment on AWS.

---
## Installing this Chart

1. Check out this git repository.

2. Install this chart using the following:
  
```helm install nxrm nxrm3-ha-repository/nxrm-aws-ha-helm -f values.yaml```
  
3. Get the Nexus Repository link using the following:
  
```kubectl get ingresses -n nexusrepo```

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
  
After removing the deployment, ensure that the namespace is deleted and that Nexus Repository is not listed when using the following:
  
  ```helm list```
