#!/bin/bash
#Script to generate pom dependencies

pre_setup()
{
	echo "Started Running Presetup"
	chmod +x cleanupfiles.sh
	sh cleanupfiles.sh

	echo "Completed Presetup"
}

populate_metadata()
{
	echo "Started Running populate_metadata()"
	find . -name '*.jar' > tmpfile
	cat tmpfile | sed -e 's/\.\///' > filelist.txt
	rm tmpfile

	sort -u filelist.txt
	#metadata_file_name=$1
	#metadata_file_name=library_metadata.txt
	#echo -e "FileName \t JarName \t CurrentVersion \t UpgradeVersion \t IsModified \t IsUpgradable \t groupId \t artifactId">> library_metadata.txt
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
		versionId=1.0
		latestVersionId=1.0

		if [ $isModified == 0 ];
		then
			artifactId=$proj_name'-lib-'$jar_vendor
			groupId=$comp_name'.'$proj_name'.'$jar_vendor
			echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId >> library_metadata.txt
		else

			groupId=`get_groupId $json_data`
			artifactId=`get_artifactId $json_data`
			versionId=`get_versionId $json_data`
			latestVersionId=`get_latest_versionID $groupId $artifactId`

			if [[ -z "$versionId" ]] || [[ -z "$groupId" ]] || [[ -z "$artifactId" ]] || [[ -z "$latestVersionId" ]];
			then
				echo $json_data >> failing_jars.txt
				echo $jar_vendor >> failing_jars.txt
				versionId=1.0
				latestVersionId=1.0
				isModified=0
				artifactId=$proj_name'-lib-'$jar_vendor
				groupId=$comp_name'.'$proj_name'.'$jar_vendor

				echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId>> library_metadata.txt
			else
				echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId>> library_metadata.txt
			fi
		fi
	done;
	echo "completed populate_metadata()"
}

generate_installer_file()
{
	echo "Started Running generate_installer_file()"
	
	url=$1
	arti_install=$2
	if [ -z $url ]; then
		url='localhost'
	fi
	
	readarray rows < library_metadata.txt

	for rowvalue in "${rows[@]}";
	do
		rowarray=(${rowvalue});
		file_name=${rowarray[0]};
		currentVersion=${rowarray[2]};
		isModified=${rowarray[4]};
		groupId=${rowarray[6]};
		artifactId=${rowarray[7]};

		if [ $isModified == 0 ] && [ "$arti_install" -eq 0 ] ;
		then
			echo 'echo installing '$file_name' in local maven repo as '$artifactId >> local_install.sh

			echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId='$groupId' -DartifactId='$artifactId' -Dversion='$currentVersion' -Dpackaging=jar  2> /dev/null	' >>local_install.sh;
			echo 'if [ "$?" -ne 0 ] ; then' >> local_install.sh ;
			echo 'echo "could not perform installation"; exit $rc' >> local_install.sh ;
			echo "fi" >> install.sh ;
			echo " " >> install.sh ;
		fi
		if [ $isModified == 0 ] && [ "$arti_install" -eq 1 ];
		then
			echo 'echo installing '$file_name' in artifactory repo as '$artifactId >> deploy_install.sh

			echo 'mvn deploy:deploy-file -DrepositoryId=releases -Durl=http://'$url':8081/artifactory/libs-release -Dfile='$file_name' -DgroupId='$groupId' -DartifactId='$artifactId' -Dversion='$currentVersion' -Dpackaging=jar  2> /dev/null	' >>deploy_install.sh;
			echo 'if [ "$?" -ne 0 ] ; then' >> deploy_install.sh ;
			echo 'echo "could not perform installation"; exit $rc' >> deploy_install.sh ;
			echo "fi" >> deploy_install.sh ;
			echo " " >> deploy_install.sh ;
		fi
	done
	
	echo "Completed generate_installer_file()"
}
generate_pom()
{
	artifactory_url=$1
	echo "Started Running generate_pom()"
	readarray rows < library_metadata.txt

	cat pom_stub.txt >> pom.xml
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
		temp=$( sed -i 's/artifactory_url/'"$artifactory_url"'/' pom.xml)
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
	echo "Completed generate_pom()"
}

install_dependencies(){
	isArtifact=$1
	echo "Installing all dependencies"
	
	if [ "$isArtifact" -eq 1 ]; then
		chmod +x deploy_install.sh
		bash deploy_install.sh
	else
		chmod +x local_install.sh
		bash local_install.sh
	fi

	echo "Completed installing dependencies"
}

run_gen_pom()
{
	echo "Running maven install for the project"
	
	if [ "$isTest" -eq 1 ]; then
		mv temp_pom.xml example/pom.xml
		cd example
	else
		mv temp_pom.xml pom.xml
	fi
	
	
	mvn clean install -q 2> /dev/null
	if [ "$?" -ne 0 ] ; then
	  echo 'could not perform installation'; exit $rc
	fi
	if [ "$?" -eq 0 ] ; then
	  echo 'Maven project compiled successfully'; exit $rc
	fi

	if [ "$isTest" -eq 1 ]; then
		cd ..
	fi

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
		groupId=`echo $1 |   grep -Po '"g":"\K[^"\047]+(?=["\047])' | xargs`
		echo $groupId
}

get_artifactId()
{
		artifactId=`echo $1 | grep -Po '"a":"\K[^"\047]+(?=["\047])' | xargs`
		echo $artifactId
}

get_versionId()
{
		versionId=`echo $1 | grep -Po '"v":"\K[^"\047]+(?=["\047])' | xargs`
		echo $versionId
}

get_latest_versionID()
{
		## To find latest availabe version
		groupId=$1
		artifactId=$2
		latVerResponse=$(curl -s https://search.maven.org/solrsearch/select?q=g:"$groupId"+AND+a:"$artifactId"&core=gav&rows=20&wt=json)

		formatLatVerResponse=`echo $latVerResponse | grep -Po '"response":*.*'`

		latestVersionId=`echo $formatLatVerResponse | grep -Po '"latestVersion":"\K[^"\047]+(?=["\047])' | xargs`
		echo $latestVersionId
}

jar_upgradable()
{
	#echo 'Checking '$1' for version upgrade'
	echo "True"
	#return 0
}

comp_name=$1
proj_name=$2
artifactory=$3
arti_install=$4
isTest=$5
if [ -z $comp_name ];
then
	comp_name='com'
fi

if [ -z $proj_name ];
then
	proj_name='sach'
fi

if [ -z $artifactory ];
then
	artifactory='localhost'
fi

if [ -z $arti_install ];
then
	arti_install=1
fi

if [ -z $isTest ];
then
	isTest=1
fi

pre_setup
populate_metadata
generate_pom $artifactory
generate_installer_file $artifactory $arti_install

mv pom.xml temp_pom.xml
install_dependencies $arti_install
run_gen_pom $isTest
