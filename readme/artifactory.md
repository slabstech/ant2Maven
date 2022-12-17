### Dependency install


#### execute scripts/install_artifactory.sh or follow steps given in below steps and then from links for docker

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


#### Attached settings from maven - maven_generated.txt
#### find sample settings.xml to be placed in .m2 folder


#### test cases using BATS
https://medium.com/@pimterry/testing-your-shell-scripts-with-bats-abfca9bdc5b9
https://github.com/sstephenson/bats
