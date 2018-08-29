#!/bin/bash
#Script to remove temporary files
if [ -f data/filelist.txt ]
then
	rm data/filelist.txt
fi

if [ -f example/pom.xml ]
then
	rm example/pom.xml
fi

if [ -f data/library_metadata.txt ]
then
	rm data/library_metadata.txt
fi

if [ -f scripts/deploy_install.sh ]
then
	rm scripts/deploy_install.sh
fi

if [ -f scripts/local_install.sh ]
then
	rm scripts/local_install.sh
fi

if [ -f data/pom.xml ]
then

	rm data/pom.xml
fi

if [ -d example/target ]
then
  rm -r example/target
fi

if [ -d example/build ]
then
  rm -r example/build
fi

if [ -d META-INF ]
then
	rm -rf META-INF
fi

if [ -f data/jar-sha1sums.txt ]
then
	rm data/jar-sha1sums.txt
fi

if [ -f data/failing_jars.txt ]
then
	rm data/failing_jars.txt
fi

if [ -f data/modified_jars.txt ]
then
	rm data/modified_jars.txt
fi

if [ -f data/central_maven_jars.txt ]
then
	rm data/central_maven_jars.txt
fi

if [ -f data/process_central.txt ]
then
	rm data/process_central.txt
fi

if [ -f data/process_modified.txt ]
then
	rm data/process_modified.txt
fi

if [ -f scripts/library_removal.sh ]
then
	rm scripts/library_removal.sh
fi
