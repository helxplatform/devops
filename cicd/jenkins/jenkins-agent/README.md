# jenkins-docker-builder.edc.renci.org

The VM jenkins-docker-builder.edc.renci.org was created in response to RT#5278. It runs a Jenkins agent that connects to jenkins.apps.renci.org (in Sterling) and runs jobs that cannot run inside Sterling, such as docker-compose jobs or jobs that require a lot of ephemeral-storage space. The VM ONLY runs the Jenkins Agent, not the Controller. Agents have no UI and don't do anything except run jobs that the Controller (jenkins.apps.renci.org) tells it to run.

## How this VM was set up

* Set up the NAT Gateway for outbound internet access: https://aciswiki.edc.renci.org/index.php?title=EDC_NAT_Gateway
* Expand the /var partition up to 60GB: `lvextend -r -L +52G /dev/VGos/var && xfs_growfs /dev/mapper/VGos-var`
* Install docker: https://docs.docker.com/engine/install/centos/
* Configure docker to rotate container logs: https://docs.docker.com/config/containers/logging/configure/
* Enable and start docker. Add users to docker group: `usermod -aG docker <user>`
  - Allowed users: machaffe, tcheek, jeffw, bennettc
* Allow the Jenkins gid (1000) to access the docker socket: `sudo setfacl -m g:1000:rw /var/run/docker.sock`
* Copy this readme and docker-compose.yml into `/opt/jenkins`
* Make /opt/jenkins group-accessible via the "renci" group
* Create a new agent in the Jenkins UI, copy the secret key
* Insert the secret key into docker-compose.yml, in place of `${AGENT_SECRET}`
* Start the agent and docuum

## Accessing the VM and Starting the Agent

All devsecops members can access the VM with their RENCI username/password:
```
ssh <renciusername>@jenkins-docker-builder.edc.renci.org
cd /opt/jenkins
docker compose up -d
```

The image is pushed here (manually for now): https://containers.renci.org/harbor/projects/5/repositories/agent-docker/info-tab

## Cleaning up old images

Docker images accumulate over time, so we use https://github.com/stepchowfun/docuum to clean them up when they use >40GB of the 60GB partition
