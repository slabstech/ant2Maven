# ant2Maven

## Script to update ant based project to maven project


### To execute
```
git clone https://github.com/sachinsshetty/ant2Maven.git
cd ant2Maven
# bash scripts/ant2Maven.sh <company_name> <project_name> <artifact_repo_url> <isArtfifactoryUrl> <isTestRun>
## Example - To deploy to artifactory
bash scripts/ant2Maven.sh com proj 192.168.100.100 1 0

### Example - Test code execution - local installing
bash scripts/ant2Maven.sh com proj localhost 0 1

```
### Workflow
* ##### Find version of jars of manifest file.
* ##### Fetch jar from maven repository using curl
* #### Match based on checksum and search for latest version
* ##### If modification is found, use existing jar in pom.xml
* ##### Fix tree dependency issue from different repos

### TODO

* #### Version 1

    * ##### find corresponding jar from maven repository and replace in pom file.
    * ##### ignore build directory
* ##### Version 2
    * ##### Handle multiple jars found from sha1sum. numFound>1
    * ##### Remove duplicates jar
    * ##### Remove low level/ transitive jars

* #### Version 3
    * ##### Add ignore jar list
    * ##### Use Maven dependency tree
    * ##### Jar file analysis


### Steps to Create a docker jfrog artifactory in Ubuntu-VM

### Dependency install


### execute scripts/install_artifactory.sh or follow steps given in below steps and then from links for docker

````
1. sudo apt update
2. sudo apt install default-jre
3. sudo apt install default-jdk
4. sudo apt install openjdk-8-jdk
5. sudo update-alternatives --config java
6. sudo apt install maven
7. Copy settings folder to .m2/ folder
````

https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository


https://www.jfrog.com/confluence/display/RTF/Installing+with+Docker


## Attached settings from maven - maven_generated.txt
### find sample settings.xml to be placed in .m2 folder

#### Bash naming convention
https://google.github.io/styleguide/shell.xml
