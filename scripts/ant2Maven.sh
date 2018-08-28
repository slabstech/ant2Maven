#!/bin/bash
#Script to generate pom dependencies

comp_name=$1
proj_name=$2
artifactory_url=$3
arti_install=$4
isTest=$5

pre_setup()
{
	echo "Started Running Presetup"
	chmod +x scripts/cleanup_files.sh
	bash scripts/cleanup_files.sh

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
	#echo -e "FileName \t JarName \t current_version \t upgrade_version \t is_modified \t IsUpgradable \t group_id \t artifact_id">> library_metadata.txt
	for file_name in $(cat data/filelist.txt);
	do
		json_data=$(jar_json_maven_repo $file_name)

		is_modified=$(jar_modification $json_data)

		is_upgradable=0
		#isUpgradable=`jar_upgradable $file_name`
		fname=$(basename $file_name);
		if [ -d META-INF ]
		then
			rm -rf META-INF
		fi

		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;
		version_id=1.0
		latest_version_id=1.0

		if [ $is_modified == 0 ];
		then
			artifact_id=$proj_name'-lib-'$jar_vendor
			group_id=$comp_name'.'$proj_name'.'$jar_vendor
			echo -e $file_name' \t '$fname'\t '$version_id' \t '$latest_version_id' \t '$is_modified' \t '$is_upgradable ' \t '$group_id' \t '$artifact_id >> data/library_metadata.txt
		else

			group_id=`get_group_id $json_data`
			artifact_id=`get_artifact_id $json_data`
			version_id=`get_version_id $json_data`
			latest_version_id=`get_latest_version_id $group_id $artifact_id`

			if [[ -z "$version_id" ]] || [[ -z "$group_id" ]] || [[ -z "$artifact_id" ]] || [[ -z "$latest_version_id" ]];
			then
				echo $json_data >> data/failing_jars.txt
				echo $jar_vendor >> data/failing_jars.txt
				version_id=1.0
				latest_version_id=1.0
				is_modified=0
				artifact_id=$proj_name'-lib-'$jar_vendor
				group_id=$comp_name'.'$proj_name'.'$jar_vendor

				echo -e $file_name' \t '$fname'\t '$version_id' \t '$latest_version_id' \t '$is_modified' \t '$is_upgradable ' \t '$group_id' \t '$artifact_id>> data/library_metadata.txt
			else
				echo -e $file_name' \t '$fname'\t '$version_id' \t '$latest_version_id' \t '$is_modified' \t '$is_upgradable ' \t '$group_id' \t '$artifact_id>> data/library_metadata.txt
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

	for row_value in "${rows[@]}";
	do
		row_array=(${row_value});
		file_name=${row_array[0]};
		current_version=${row_array[2]};
		is_modified=${row_array[4]};
		group_id=${row_array[6]};
		artifact_id=${row_array[7]};

		if [ $is_modified == 0 ] && [ "$arti_install" -eq 0 ] ;
		then
			echo 'echo installing '$file_name' in local maven repo as '$artifact_id >> scripts/local_install.sh

			echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId='$group_id' -DartifactId='$artifact_id' -Dversion='$current_version' -Dpackaging=jar  2> /dev/null	' >> scripts/local_install.sh;
			echo 'if [ "$?" -ne 0 ] ; then' >> scripts/local_install.sh ;
			echo 'echo "could not perform installation"; exit $rc' >> scripts/local_install.sh ;
			echo "fi" >> scripts/local_install.sh ;
			echo " " >> scripts/local_install.sh ;
		fi
		if [ $is_modified == 0 ] && [ "$arti_install" -eq 1 ];
		then
			echo 'echo installing '$file_name' in artifactory repo as '$artifact_id >> scripts/deploy_install.sh

			echo 'mvn deploy:deploy-file -DrepositoryId=releases -Durl=http://'$url':8081/artifactory/libs-release -Dfile='$file_name' -DgroupId='$group_id' -DartifactId='$artifact_id' -Dversion='$current_version' -Dpackaging=jar  2> /dev/null	' >> scripts/deploy_install.sh;
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
	for row_value in "${rows[@]}";
	do
		row_array=(${row_value});
		fname=${row_array[1]};
		current_version=${row_array[2]};
		upgrade_version=${row_array[3]};
		is_modified=${row_array[4]};
		group_id=${row_array[6]};
		artifact_id=${row_array[7]};

		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;
		temp=$( sed -i 's/artifactory_url/'"$artifactory_url"'/' data/pom.xml)
		echo -e '\t\t<dependency>' >> data/pom.xml
		if [ $is_modified == 0 ];
		then
			echo -e '\t\t\t<groupId>'$group_id'</groupId>' >> data/pom.xml
			echo -e '\t\t\t<artifactId>'$artifact_id'</artifactId>' >> data/pom.xml
			echo -e '\t\t\t<version>'$current_version'</version>'>> data/pom.xml
		else
			echo -e '\t\t\t<groupId>'$group_id'</groupId>' >> data/pom.xml
			echo -e '\t\t\t<artifactId>'$artifact_id'</artifactId>' >> data/pom.xml
			echo -e '\t\t\t<version>'$upgrade_version'</version>'>> data/pom.xml
		fi
		echo -e '\t\t</dependency>' >> data/pom.xml

	done

	echo -e '</dependencies>
		</project>' >> data/pom.xml
	echo "Completed generate_pom()"
}

install_dependencies(){
	is_artifact=$1
	echo "Installing all dependencies"

	if [ "$is_artifact" -eq 1 ]; then
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

	is_test=$1
	if [ "$is_test" -eq 1 ]; then
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
		shaVal=$(cat data/jar-sha1sums.txt | cut -d " " -f1)
		value=$(curl -s 'http://search.maven.org/solrsearch/select?q=1:%22'$shaVal'%22&rows=20&wt=json')
		echo $value | grep -Po '"response":*.*'
}

jar_modification()
{
		is_found=$(echo $1 | grep -Po '"numFound":[0-9]' | cut -d ":" -f2)
		echo $is_found
}

get_group_id()
{
		group_id=$(echo $1 |   grep -Po '"g":"\K[^"\047]+(?=["\047])' | xargs)
		echo $group_id
}

get_artifact_id()
{
		artifact_id=$(echo $1 | grep -Po '"a":"\K[^"\047]+(?=["\047])' | xargs)
		echo $artifact_id
}

get_version_id()
{
		version_id=$(echo $1 | grep -Po '"v":"\K[^"\047]+(?=["\047])' | xargs)
		echo $version_id
}

get_latest_version_id()
{
		## To find latest availabe version
		group_id=$1
		artifact_id=$2
		lat_ver_response=$(curl -s https://search.maven.org/solrsearch/select?q=g:"$group_id"+AND+a:"$artifact_id"&core=gav&rows=20&wt=json)

		format_lat_ver_response=$(echo $lat_ver_response | grep -Po '"response":*.*')

		latest_version_id=$(echo $format_lat_ver_response | grep -Po '"latestVersion":"\K[^"\047]+(?=["\047])' | xargs)
		echo $latest_version_id
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


main()
{
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

	if [ -z $is_test ];
	then
		is_test=1
	fi

	printParameters $comp_name $proj_name $artifactory_url $arti_install $isTest
	pre_setup
	populate_metadata
	generate_pom $artifactory_url
	generate_installer_file $artifactory_url $arti_install

	mv data/pom.xml data/temp_pom.xml
	install_dependencies $arti_install
	run_gen_pom $is_test

}

main $comp_name $proj_name $artifactory_url $arti_install $isTest
