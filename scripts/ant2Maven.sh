#!/bin/bash
#Script to generate pom dependencies

pre_setup()
{
	echo "Started Running Presetup"
	chmod +x scripts/cleanupfiles.sh
	bash scripts/cleanupfiles.sh

	echo "Completed Presetup"
}

populate_metadata()
{
	echo "Started Running populate_metadata()"
	find . -name '*.jar' > tmpfile
	cat tmpfile | sed -e 's/\.\///' > data/filelist.txt
	rm tmpfile

	temp=$(sort -u data/filelist.txt)
	#metadata_file_name=$1
	#metadata_file_name=library_metadata.txt
	#echo -e "FileName \t JarName \t CurrentVersion \t UpgradeVersion \t IsModified \t IsUpgradable \t groupId \t artifactId">> library_metadata.txt
	for file_name in `cat data/filelist.txt`;
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
			echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId >> data/library_metadata.txt
		else

			groupId=`get_groupId $json_data`
			artifactId=`get_artifactId $json_data`
			versionId=`get_versionId $json_data`
			latestVersionId=`get_latest_versionID $groupId $artifactId`

			if [[ -z "$versionId" ]] || [[ -z "$groupId" ]] || [[ -z "$artifactId" ]] || [[ -z "$latestVersionId" ]];
			then
				echo $json_data >> data/failing_jars.txt
				echo $jar_vendor >> data/failing_jars.txt
				versionId=1.0
				latestVersionId=1.0
				isModified=0
				artifactId=$proj_name'-lib-'$jar_vendor
				groupId=$comp_name'.'$proj_name'.'$jar_vendor

				echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId>> data/library_metadata.txt
			else
				echo -e $file_name' \t '$fname'\t '$versionId' \t '$latestVersionId' \t '$isModified' \t '$isUpgradable ' \t '$groupId' \t '$artifactId>> data/library_metadata.txt
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
	
	readarray rows < data/library_metadata.txt

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
			echo 'echo installing '$file_name' in local maven repo as '$artifactId >> scripts/local_install.sh

			echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId='$groupId' -DartifactId='$artifactId' -Dversion='$currentVersion' -Dpackaging=jar  2> /dev/null	' >> scripts/local_install.sh;
			echo 'if [ "$?" -ne 0 ] ; then' >> scripts/local_install.sh ;
			echo 'echo "could not perform installation"; exit $rc' >> scripts/local_install.sh ;
			echo "fi" >> scripts/local_install.sh ;
			echo " " >> scripts/local_install.sh ;
		fi
		if [ $isModified == 0 ] && [ "$arti_install" -eq 1 ];
		then
			echo 'echo installing '$file_name' in artifactory repo as '$artifactId >> scripts/deploy_install.sh

			echo 'mvn deploy:deploy-file -DrepositoryId=releases -Durl=http://'$url':8081/artifactory/libs-release -Dfile='$file_name' -DgroupId='$groupId' -DartifactId='$artifactId' -Dversion='$currentVersion' -Dpackaging=jar  2> /dev/null	' >> scripts/deploy_install.sh;
			echo 'if [ "$?" -ne 0 ] ; then' >> scripts/deploy_install.sh ;
			echo 'echo "could not perform installation"; exit $rc' >> scripts/deploy_install.sh ;
			echo "fi" >> scripts/deploy_install.sh ;
			echo " " >> scripts/deploy_install.sh ;
		fi
	done
	
	echo "Completed generate_installer_file()"
}
generate_pom()
{
	artifactory_url=$1
	echo "Started Running generate_pom()"
	readarray rows < data/library_metadata.txt

	cat data/pom_stub.txt >> data/pom.xml
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
		temp=$( sed -i 's/artifactory_url/'"$artifactory_url"'/' data/pom.xml)
		echo -e '\t\t<dependency>' >> data/pom.xml
		if [ $isModified == 0 ];
		then
			echo -e '\t\t\t<groupId>'$groupId'</groupId>' >> data/pom.xml
			echo -e '\t\t\t<artifactId>'$artifactId'</artifactId>' >> data/pom.xml
			echo -e '\t\t\t<version>'$currentVersion'</version>'>> data/pom.xml
		else
			echo -e '\t\t\t<groupId>'$groupId'</groupId>' >> data/pom.xml
			echo -e '\t\t\t<artifactId>'$artifactId'</artifactId>' >> data/pom.xml
			echo -e '\t\t\t<version>'$upgradeVersion'</version>'>> data/pom.xml
		fi
		echo -e '\t\t</dependency>' >> data/pom.xml

	done

	echo -e '</dependencies>
		</project>' >> data/pom.xml
	echo "Completed generate_pom()"
}

install_dependencies(){
	isArtifact=$1
	echo "Installing all dependencies"
	
	if [ "$isArtifact" -eq 1 ]; then
		chmod +x scripts/deploy_install.sh
		bash scripts/deploy_install.sh
	else
		chmod +x scripts/local_install.sh
		bash scripts/local_install.sh
	fi

	echo "Completed installing dependencies"
}

run_gen_pom()
{
	echo "Running maven install for the project"
	
	if [ "$isTest" -eq 1 ]; then
		mv data/temp_pom.xml example/pom.xml
		mvn clean install -f example/pom.xml -q 2> /dev/null
		if [ "$?" -eq 0 ] ; then
			echo 'Maven project compiled successfully'; exit $rc
		fi
	else
		mv data/temp_pom.xml data/pom.xml
	fi

}

jar_json_maven_repo()
{
		sha1sum $1 > data/jar-sha1sums.txt
		shaVal=`cat data/jar-sha1sums.txt | cut -d " " -f1`
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

printParameters()
{
	echo -e "\nRunning ant2Maven Script with below parameters \n"
	echo -e 'CompanyName =' $1' ProjectName = '$2' Artifactory_URL = '$3' IsArtifactoryInstall = '$4' IsTestRun = '$5' \n'
	
}

comp_name=$1
proj_name=$2
artifactory_url=$3
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

if [ -z $artifactory_url ];
then
	artifactory_url='localhost'
fi

if [ -z $arti_install ];
then
	arti_install=1
fi

if [ -z $isTest ];
then
	isTest=1
fi

printParameters $comp_name $proj_name $artifactory_url $arti_install $isTest
pre_setup
populate_metadata
generate_pom $artifactory_url
generate_installer_file $artifactory_url $arti_install

mv data/pom.xml data/temp_pom.xml
install_dependencies $arti_install
run_gen_pom $isTest
