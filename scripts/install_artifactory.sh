sudo apt update
sudo apt install default-jre
sudo apt install default-jdk
sudo apt install openjdk-8-jdk
sudo update-alternatives --config java
##TODO How to select openjdk8
sudo apt install maven
# Copy settings folder to .m2/ folder


##Installing docker
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install docker-ce

sudo docker pull docker.bintray.io/jfrog/artifactory-oss:latest

sudo docker run --name artifactory -d -p 8081:8081 docker.bintray.io/jfrog/artifactory-oss:latest
