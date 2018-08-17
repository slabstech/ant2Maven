#!/bin/sh
#Script to remove temporary files
if [ -f filelist.txt ]
then
	rm filelist.txt
fi

if [ -f install.txt ]
then
	rm install.txt
fi

if [ -f new_pom.xml ]
then
	rm new_pom.xml
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
