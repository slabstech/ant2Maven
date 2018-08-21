# ant2Maven

## Script to update ant based project to maven project


## To execute
## git clone https://github.com/sachinsshetty/ant2Maven.git
## cd ant2Maven
## bash script.sh



## Workflow
* ### Find version of jars of manifest file.
* ### Fetch jar from maven repository using curl
* ### Match based on checksum and search for latest version
* ### If modification is found, use existing jar in pom.xml
* ### Fix tree dependency issue from different repos


# TODO

* ## Version1
    * ### Remove duplicates jar
    * ### Remove low level jars
    * ### find corresponding jar from maven repository and replace in pom file.
    * ### fix maven tree dependency
    * ### ignore build directory
* ## Version2
    * ## Handle multiple jars found from sha1sum. numFound>1
