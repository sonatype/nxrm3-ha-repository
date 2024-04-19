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
* A disk accessible to all active nodes for storing Nexus Repository logs and configuration settings used for generating the support zip

If the Nexus Repository deployment will contain more than one Docker repository,  you must use one of the following:
* An external load balancer (e.g., NGINX) as a [reverse proxy](https://help.sonatype.com/display/NXRM3M/Docker+Repository+Reverse+Proxy+Strategies) instead of the provided ingress for Docker YAML 
* A [Docker Subdomain Connector](https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/docker-registry/docker-subdomain-connector) with external DNS to route traffic to each Docker subdomain
