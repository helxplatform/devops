# Continuous Integration/Continuous Delivery


![HeLX CICD Pipeline](images/CICD_pipeline.png "HeLX CICD Pipeline")

##

## Build

### Jenkins
1) **General Approach**
2) **System Architecture**\
    a) **Machine User**\
    A machine user has been created to represent developers on Github, and Dockerhub to prevent the need for individual userids and passwords from needing to be used. This user's userid is ***rencibuild*** and has an email address of ***helx-dev@lists.renci.org***. The use of a list email address allows multiple users to monitor incoming correspondence from Github and Dockerhub and respond as needed.\
    This user of necessity has privileges on many helxplatform GitHub repos that allow it to create repos and actions as well as respond to commits, etc. It's also an organization member on DockerHub so that it can push images.
  
    b) **Docker**\
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
8) This sets up an action on the **default** branch, which must be done before setting up an action on any non-default branch. To set up an action on a non-default branch after saving this file, **merge** this file to the desired branch. **Copying it in will not work.**
```````````````````````````````````````````````````````````````````````````````````````````````````````````````
name: Linter

on:
  push:
    branches: [ master ]
    
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
        OUTPUT_FOLDER: SL_LOGS
```````````````````````````````````````````````````````````````````````````````````````````````````````````````

**Notes:**
  - The action is triggered on commits to GitHub (see "on: push:" in the yaml).
  - The yaml file passes a GitHub token to the workflow. However, there's a GitHub bug which causes it to to not recognize the token, so the logs will complain about not getting one. The action works anyway.
  - Super-Linter was designed to be used with a pull request model rather than using a push event. That would allow the developer to fix any linting errors under the pull request before it is closed and is thus cleaner as the commmit will ultimately show a check next to it since you can make multiple commits under a pull request. With a push model, if there are errors, an "x" will show for that commit and it must be fixed with a second commit, which will then have a check next to it.
  - GitHub hints that it has plans to move Super-Linter "closer to the developer" in the future. But for now, using it locally is unsupported. That said, it is possible to get it to run locally using the instructions found [here](https://github.com/github/super-linter/blob/master/docs/run-linter-locally.md). However, it was not possible to get it running directly in a container on the server in the time available and may not be possible until GitHub develops it further.

### Using Super-Linter in Development:
Details to come.

## Unit Test

## Containerize

## Security Scan
