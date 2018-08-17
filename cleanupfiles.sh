#!/bin/sh
#Script to remove temporary files
if [ -f filelist.txt ]
then
	rm filelist.txt
fi

if [ -f pom.xml ]
then
	rm pom.xml
fi

if [ -f library_metadata.txt ]
then
	rm library_metadata.txt
fi

if [ -f install.sh ]
then
	rm install.sh
fi

if [ -f example/pom.xml ]
then

	rm example/pom.xml
fi

if [ -d example/target ]
then
  rm -r example/target
fi

if [ -d META-INF ]
then
	rm -rf META-INF
fi

if [ -f jar-sha1sums.txt ]
then
	rm jar-sha1sums.txt
fi
