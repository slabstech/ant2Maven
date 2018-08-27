# ant2Maven

## Script to update ant based project to maven project


### To execute
```
git clone https://github.com/sachinsshetty/ant2Maven.git
cd ant2Maven
# bash script.sh <company_name> <project_name> <artifact_repo_url> <isArtfifactoryUrl> <isTestRun>
## Example
bash script.sh efi pace 192.168.220.133 1 0

```
### Workflow
* #### Find version of jars of manifest file.
* #### Fetch jar from maven repository using curl
* #### Match based on checksum and search for latest version
* #### If modification is found, use existing jar in pom.xml
* #### Fix tree dependency issue from different repos

### TODO

* #### Version1
    * ##### Remove duplicates jar
    * ##### Remove low level jars
    * ##### find corresponding jar from maven repository and replace in pom file.
    * ##### fix maven tree dependency
    * ##### ignore build directory
* ##### Version2
    * ##### Handle multiple jars found from sha1sum. numFound>1


### Steps to Create a docker jfrog artifactory in Ubuntu-VM

### Dependency install


### execute install_artifactory.sh or follow steps given in below steps and then from links for docker

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
