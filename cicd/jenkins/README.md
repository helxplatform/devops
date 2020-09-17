# Continuous Integration/Continuous Delivery


![HeLX CICD Pipeline](images/CICD_pipeline.png "HeLX CICD Pipeline")

##
Continuous Integration/Continuous Delivery (CI/CD) is a set of best practices implemented through automation that raise code quality, increase developer productivity, detect defects and security issues as early as possible, and help deliver high quality software to customers. Because it removes significant overhead from developers, it speeds development and lowers development costs.

CI/CD is implemented as an automation pipeline. The HeLX CI/CD pipeline consists of build, static analysis, unit test, containerization, security scanning, and deployment stages.

## Build

### Jenkins
1) **General Approach**\
The HeLX CI/CD is based on a pipeline of services that process, test, package, and deploy the code. To the extent possible, these services are run on and by a Jenkins server run on a cluster hosted at RENCI. This Jenkins server is run as a Docker container managed by Kubernetes on the cluster.

   The one exception to this is static analysis, which is run on GitHub, due to the choice to use the Super-Linter lint aggregator. It runs as a Github workflow action on GitHub servers.

   Using a containerized Jenkins server allows the entire CI/CD pipeline to be backed up and restored in the case of a crash or outage along with its build data, along with all the other normal benefits of containerized services.

2) **System Architecture**\
    a) **Machine User**\
    A machine user represents developers on Github and Dockerhub to prevent the need for any individual userids and passwords in build scripts. This user's userid is ***rencibuild*** and has an email address of ***helx-dev@lists.renci.org***. The use of a list email address allows multiple users to monitor incoming correspondence from Github and Dockerhub and respond as needed.
    
    This user of necessity has privileges on many helxplatform GitHub repos that allow it to create repos and actions as well as respond to commits, etc. It's also an organization member on DockerHub so that it can push images.
  
    b) **Docker**\
    The Jenkins server is based on the Jenkins:lts Docker image, with modifications required for HeLX. This includes modifications for running Docker in a Docker container, docker-ce, docker-ce-cli, docker-compose, building certain languages, clair security scanner, and tools to ease administration (curl, less, vim-tiny, sudo).
    
    Most changes are added as the **root** user. Although its not visible in our Dockerfile, the jenkins:lts image does add a **jenkins** user Our Dockerfile switches to the **jenkins** user before adding some file changes which need **jenkins** user file permissions. This also becomes the running user on the container. One additional user, **jovyan**, is added, which is required for the blackbalsam build.
    
    The [Dockerfile](https://github.com/helxplatform/devops/cicd/jenkins/jenkins-master/docker/Dockerfile) is located in the GitHub 
**helxplatform/devops repo**.
    
    c) **Kubernetes**
    
3) **Build Scripts**
4) **Versioning**\
There are two types of versioning currently used in HeLX CICD, manual and automatic. Most projects use automatic versioning with a small number (2-3) still using the older manual approach. They will be converted eventually so that there's only one versioning approach.
  
    a) **Manual**\
    Manual versioning works with the use of a hidden .ver file which contains the version number. This file typically lives in the top level bin directory or in some cases in docker/bin where the comp shell scripts exists. Developers increment the version in this file when they wish to bump the version up. TranQL is an example of a project currently using this type of versioning. Code typically retrieves the version in a build script this way:
    ```````````````````````````````
    ver=$(cat ./docker/bin/.ver)
    ```````````````````````````````
    This can help identify manually versioned build scripts.  
    
    b) **Automatic**\
    Automatic versioning uses two bash functions and a version files on the jenkins server to manage version numbers. These functions, get_ver and incr_ver, live in bash_lib on GitHub in the devops repo. The version files are initially set by the build script under the jobs directory for the project's build. For example, for the develop build for appstore, the version file will be set at:
    `````````````````````````````````````````````````
    $JENKINS_HOME/jobs/appstore/version/develop/ver
    `````````````````````````````````````````````````
    The format of the version file is:
    `````````````````````````````````````````````````
    vN.N.NN
    `````````````````````````````````````````````````
    where 'v' is simply the letter 'v', each N stands for a single integer 0-9, and '.' is the decimal point.\
    incr_ver is set up to increment the two digit portion from 1-99 and the single digit portions from 0-9. If a need arises to increment an image differently, for example, to go from v0.0.48 to v1.0.0, the file can be edited manually, and the automation will continue incrementing at v1.0.1.

## Static Analysis/Lint

### Introduction
GitHub has a new static analysis tool called [Super-Linter](https://github.com/github/super-linter), which HeLX CI/CD uses in as the first step in its pipeline. This tool aggregates linters for 36 different programming languages. Some languages, in turn, have as many as four different linters each. Python, for example, has three, **pylint**, **flake8**, and **black**.

### Set up:
Super-Linter runs as a GitHub [Action](https://github.com/features/actions). Actions are workflows that run on GitHub. As such, they must be set up directly on GitHub and don't run directly on the Jenkins server like the rest of the CI/CD pipeline. 

Here are the steps to set up a new repo for the Super-Linter action:
1) Ensure that the machine user has admin permissions for the repo.
2) Log into GitHub as the machine user.
3) Go to "Actions"
4) Look through the list of workflow templates and click on "Simple workflow" --> "Set up this workflow"
5) At the top of the template, give it the name **linter.yml**
6) Highlight the entire text of the workflow file and paste in the yaml text below in its place.
7) Save the file.
8) This sets up an action on the **default** branch (usually the master branch), which must be done before setting up an action on any non-default branch. To set up an action on a non-default branch after saving this file, **merge** this file to the desired branch. **Copying it in will not work.**
```````````````````````````````````````````````````````````````````````````````````````````````````````````````
name: Linter

on:
  push:
    branches: [ master, develop ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - uses: fregante/setup-git-token@v1
      with:
        token: ${{ secrets.GITHUB_TOKEN }}

    - name: Super-Linter
      uses: github/super-linter@v3
      env:
        VALIDATE_ALL_CODEBASE: false
```````````````````````````````````````````````````````````````````````````````````````````````````````````````

**Notes:**
  - The action is triggered on commits to GitHub (see "on: push:" in the yaml).
  - The yaml file passes a GitHub token to the workflow. However, there's a GitHub bug which causes it to to not recognize the token, so the logs will complain about not getting one. The action works anyway.
  - Super-Linter was designed to be used with a pull request model rather than using a push event. That would allow the developer to fix any linting errors under the pull request before it is closed and is thus cleaner as the commmit will ultimately show a check next to it since you can make multiple commits under a pull request. With a push model, if there are errors, an "x" will show for that commit and it must be fixed with a second commit, which will then have a check next to it.
  - Super-Linter defaults to linting the entire repo at once. This leads to an enormous amount of output when run on a large existing body of code. For this reason, we decided to set **VALIDATE_ALL_CODEBASE** to **FALSE**. This means that only new and changed files in a commit are linted, which is more manageable during a development cycle. In a greefield condition, setting it to **TRUE** makes more sense.
  - Other individual linter settings have been left at their defaults. With the number of linters involved, each having dozens of settings, it seemed prudent to let them run with their well-considered defaults initially and then adjust for any pain points as needed.
  - GitHub hints that it has plans to move Super-Linter "closer to the developer" in the future. But for now, using it locally is unsupported. That said, it is possible to get it to run locally using the instructions found [here](https://github.com/github/super-linter/blob/master/docs/run-linter-locally.md). However, it was not possible to get it running directly in a container on the server in the time available and may not be possible until GitHub develops it further.

### Using Super-Linter in Development:
Details to come.

## Unit Test

## Containerize

## Security Scan
