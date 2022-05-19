# jenkins-docker-builder.edc.renci.org

The VM jenkins-docker-builder.edc.renci.org was created in response to RT#5278. It runs a Jenkins agent that connects to jenkins.apps.renci.org (in Sterling) and runs jobs that cannot run inside Sterling, such as docker-compose jobs or jobs that require a lot of ephemeral-storage space.

## How this VM was set up

* Set up the NAT Gateway for outbound internet access: https://aciswiki.edc.renci.org/index.php?title=EDC_NAT_Gateway
* Install docker: https://docs.docker.com/engine/install/centos/
* Enable and start docker. Add users to docker group: `usermod -aG docker <user>`
  - Allowed users: machaffe, tcheek, jeffw, bennettc
* Allow the Jenkins gid (1000) to access the docker socket: `sudo setfacl -m g:1000:rw /var/run/docker.sock`
* Create a new agent in the Jenkins UI, copy the secret key
* Run the jenkins agent (using websockets):

```
docker run -d --name agent -v /var/run/docker.sock:/var/run/docker.sock containers.renci.org/helxplatform/agent-docker:v0.0.16 -url https://jenkins.apps.renci.org/ -webSocket -workDir /home/jenkins/agent $AGENT_SECRET jenkins-docker-builder.edc.renci.org
```

The image is pushed here (manually for now): https://containers.renci.org/harbor/projects/5/repositories/agent-docker/info-tab
