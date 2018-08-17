#!/bin/sh
#Script to generate pom dependencies

pre_setup()
{
	chmod +x cleanupfiles.sh
	sh cleanupfiles.sh

	find . -name '*.jar' | sed -e 's/\.\///' > filelist.txt

	cat pom_stub.txt >> pom.xml
	sort -u filelist.txt
}

generate_pom()
{
	echo -e "JarName \t CurrentVersion \t UpgradeVersion \t IsModified \t IsUpgradable">> library_metadata.txt

	comp_name='sample'
	for file_name in `cat filelist.txt`;
	do
		json_data=`jar_json_maven_repo $file_name`

		isModified=`jar_modification $json_data`

		groupId=`get_groupId $json_data`
		artifactId=`get_artifactId $json_data`
		versionId=`get_versionId $json_data`

		isUpgradable=True
		#isUpgradable=`jar_upgradable $file_name`
		fname=$(basename $file_name);
		if [ -d META-INF ]
		then
			rm -rf META-INF
		fi

		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;
		version=1.0

		echo -e '\t\t<dependency>' >> pom.xml
		if [ $isModified == 0 ];
		then
			echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId=com.'$comp_name'.'$jar_vendor' -DartifactId='$comp_name'-lib-'$jar_vendor' -Dversion=1.0 -Dpackaging=jar  ' >>install.sh;
			echo 'echo installing '$file_name' in local maven repo' >> install.sh
			echo " " >> install.sh ;
			echo -e $fname'\t '$version' \t '$isModified' \t '$isUpgradable >> library_metadata.txt

			echo -e '\t\t\t<groupId>com.'$comp_name'.'$jar_vendor'</groupId>' >> pom.xml
			echo -e '\t\t\t<artifactId>'$comp_name'-lib-'$jar_vendor'</artifactId>' >> pom.xml
			echo -e '\t\t\t<version>'$version'</version>'>> pom.xml

		else

			echo -e '\t\t\t<groupId>'$groupId'</groupId>' >> pom.xml
			echo -e '\t\t\t<artifactId>'$artifactId'</artifactId>' >> pom.xml
			echo -e '\t\t\t<version>'$versionId'</version>'>> pom.xml
			echo -e $fname'\t '$versionId' \t '$isModified' \t '$isUpgradable >> library_metadata.txt
		fi
		echo -e '\t\t</dependency>' >> pom.xml

	done;

	echo '</dependencies>
		</project>' >> pom.xml
}

install_dependencies(){
	chmod +x install.sh
	bash install.sh
}

run_gen_pom()
{
	mv pom.xml example/pom.xml
	cd example
	mvn clean install -q
	if [ "$?" -ne 0 ] ; then
	  echo 'could not perform installation'; exit $rc
	fi
	if [ "$?" -eq 0 ] ; then
	  echo 'Maven project compiled successfully'; exit $rc
	fi

	cd ..
}

jar_json_maven_repo()
{
		sha1sum $1 > jar-sha1sums.txt
		shaVal=`cat jar-sha1sums.txt | cut -d " " -f1`
		value=$(curl -s 'http://search.maven.org/solrsearch/select?q=1:%22'$shaVal'%22&rows=20&wt=json')
		echo $value | grep -Po '"response":*.*'
}

jar_modification()
{
		isFound=`echo $1 | grep -Po '"numFound":[0-9]' | cut -d ":" -f2`
		echo $isFound
}

get_groupId()
{
		groupId=`echo $1 |   grep -Po '"g":"[a-z]*"' | cut -d ":" -f2 | xargs`
		echo $groupId
}

get_artifactId()
{
		artifactId=`echo $1 | grep -Po '"a":"[a-z]*"' | cut -d ":" -f2 | xargs`
		echo $artifactId
}

get_versionId()
{
		versionId=`echo $1 | grep -Po '"v":"[0-9]*.[0-9]*"' | cut -d ":" -f2| xargs`
		echo $versionId
}

jar_upgradable()
{
	#echo 'Checking '$1' for version upgrade'
	echo "True"
	#return 0
}

pre_setup
generate_pom
install_dependencies
run_gen_pom
