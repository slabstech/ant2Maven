# ant2Maven [![Travis Build Status](https://img.shields.io/travis/pimterry/notes.svg)](https://travis-ci.org/sachinsshetty/ant2Maven)

## Script to update ant based project to maven project


### To execute
```
git clone https://github.com/sachinsshetty/ant2Maven.git
cd ant2Maven
# bash scripts/ant2Maven <Function type> <company_name> <project_name> <artifact_repo_url> <isArtfifactoryUrl> <isTestRun>
## Example - To deploy to artifactory
bash scripts/ant2Maven exec com proj 192.168.100.100 1 0

### Example - To run with sample project- local install
bash scripts/ant2Maven exec com proj localhost 0 1

```

### To use in your project
1. Copy data and scripts folder to project directory
2. Execute ant2Maven
3. Find the generated pom.xml, installation files in data directory .


### Test Case Execution : Using BATS
```
### Full Suite Run

bash scripts/test_suite


### Specific function test

bash scripts/ant2Maven test <function_name> <...Params ..>
##### Example :
bash scripts/ant2Maven test get_version_id

```

### TODO
| Version | Description | Status |
|-------|-------------|-------|
|1 | Find corresponding jar from maven repository and replace in pom file. |Done |
|1| Ignore Target Jar- ReRun Scenario | |
|1| Bash test case |30%|
|2 | Handle multiple jars found from sha1sum. numFound>1| |
|2 | Remove duplicates jar | Done |
|2 | Remove low level/ transitive jars||
|3| Add ignore jar list| Done |
|3| Use Maven dependency tree||
|3 | Jar file analysis| |
|4 | Generate library removal script | Done |
|4| Add ant clean execution phase | Done |
|5| Individual/Suite Test Cases Run | |


##### Steps to Create a docker jfrog artifactory in Ubuntu-VM
documented in repository_README.md

#### Bash naming convention
https://google.github.io/styleguide/shell.xml
#### Maven search api help
https://search.maven.org/classic/#api
