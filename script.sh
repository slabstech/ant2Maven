#!/bin/bash
#Script to generate pom dependencies

pre_setup()
{
	chmod +x cleanupfiles.sh
	sh cleanupfiles.sh

	find . -name '*.jar' | sed -e 's/\.\///' > filelist.txt

	cat pom_stub.txt >> pom.xml
	sort -u filelist.txt
}

populate_metadata()
{
	#metadata_file_name=$1
	#metadata_file_name=library_metadata.txt
	#echo -e "FileName \t JarName \t CurrentVersion \t UpgradeVersion \t IsModified \t IsUpgradable \t groupId \t artifactId">> library_metadata.txt
	comp_name='sample'
	for file_name in `cat filelist.txt`;
	do
		json_data=`jar_json_maven_repo $file_name`

		isModified=`jar_modification $json_data`

		isUpgradable=0
		#isUpgradable=`jar_upgradable $file_name`
		fname=$(basename $file_name);
		if [ -d META-INF ]
		then
			rm -rf META-INF
		fi

		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;
		version=1.0

		if [ $isModified == 0 ];
		then
			artifactId=$comp_name'-lib-'$jar_vendor
			groupId='com.'$comp_name'.'$jar_vendor
			echo -e $file_name' \t '$fname'\t '$version' \t '$version' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId >> library_metadata.txt
		else

			groupId=`get_groupId $json_data`
			artifactId=`get_artifactId $json_data`
			versionId=`get_versionId $json_data`
			latestVersionId=`get_latest_versionID $groupId $artifactId`

			echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId>> library_metadata.txt
		fi

	done;

}

generate_installer_file()
{
	readarray rows < library_metadata.txt

	for rowvalue in "${rows[@]}";
	do
		rowarray=(${rowvalue});
		file_name=${rowarray[0]};
		currentVersion=${rowarray[2]};
		isModified=${rowarray[4]};
		groupId=${rowarray[6]};
		artifactId=${rowarray[7]};

		if [ $isModified == 0 ];
		then
			echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId='$groupId' -DartifactId='$artifactId' -Dversion='$currentVersion' -Dpackaging=jar  ' >>install.sh;
			echo 'echo installing '$file_name' in local maven repo' >> install.sh
			echo " " >> install.sh ;
		fi

	done

}
generate_pom()
{
	readarray rows < library_metadata.txt


	for rowvalue in "${rows[@]}";
	do
		rowarray=(${rowvalue});
		fname=${rowarray[1]};
		currentVersion=${rowarray[2]};
		upgradeVersion=${rowarray[3]};
		isModified=${rowarray[4]};
		groupId=${rowarray[6]};
		artifactId=${rowarray[7]};

		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;

		echo -e '\t\t<dependency>' >> pom.xml
		if [ $isModified == 0 ];
		then
			echo -e '\t\t\t<groupId>'$groupId'</groupId>' >> pom.xml
			echo -e '\t\t\t<artifactId>'$artifactId'</artifactId>' >> pom.xml
			echo -e '\t\t\t<version>'$currentVersion'</version>'>> pom.xml
		else
			echo -e '\t\t\t<groupId>'$groupId'</groupId>' >> pom.xml
			echo -e '\t\t\t<artifactId>'$artifactId'</artifactId>' >> pom.xml
			echo -e '\t\t\t<version>'$upgradeVersion'</version>'>> pom.xml
		fi
		echo -e '\t\t</dependency>' >> pom.xml

	done

	echo -e '</dependencies>
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

get_latest_versionID()
{
		## To find latest availabe version
		groupId=$1
		artifactId=$2
		latVerResponse=$(curl -s https://search.maven.org/solrsearch/select?q=g:"$groupId"+AND+a:"$artifactId"&core=gav&rows=20&wt=json)

		formatLatVerResponse=`echo $latVerResponse | grep -Po '"response":*.*'`

		latestVersionId=`echo $formatLatVerResponse | grep -Po '"latestVersion":"[0-9]*.[0-9]*"' | cut -d ":" -f2| xargs`
		echo $latestVersionId
}
jar_upgradable()
{
	#echo 'Checking '$1' for version upgrade'
	echo "True"
	#return 0
}


pre_setup
populate_metadata
generate_pom
generate_installer_file
install_dependencies
run_gen_pom
