#!/bin/bash
#Script to generate pom dependencies

if [ "$#" -ne 6 ]; then
    echo -e "Illegal number of parameters\n"
		echo "Usage :\n"
		echo -e "bash scripts/ant2Maven.sh <company_name> <project_name> <artifact_repo_url> <artifactory_port> <isArtfifactoryUrl> <isTestRun>\n"
		echo -e "Ex. bash scripts/ant2Maven.sh com proj localhost 8081 0 1"
		exit 0
fi
comp_name=$1
proj_name=$2
artifactory_url=$3
artifactory_port=$4
arti_install=$5
isTest=$6

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
		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;
		version_id=1.0
		latest_version_id=1.0

		if [ "$is_modified" -eq 0 ];
		then
			artifact_id='lib-'$jar_vendor
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
				artifact_id='lib-'$jar_vendor
				group_id=$comp_name'.'$proj_name'.'$jar_vendor

				echo -e $file_name' \t '$fname'\t '$version_id' \t '$latest_version_id' \t '$is_modified' \t '$is_upgradable ' \t '$group_id' \t '$artifact_id>> data/library_metadata.txt
			else
				echo -e $file_name' \t '$fname'\t '$version_id' \t '$latest_version_id' \t '$is_modified' \t '$is_upgradable ' \t '$group_id' \t '$artifact_id>> data/library_metadata.txt
			fi
		fi
	done;
	echo "completed populate_metadata()"
}

process_ignore_list()
{
  readarray rows < data/ignore_jars.txt

  for row_value in "${rows[@]}";
	do
    row_array=(${row_value});
    file_type=${row_array[0]};
    file_info=${row_array[1]};
    $(sed -i '/'"$file_info"'/d' data/library_metadata.txt)
	done

}

remove_duplicates_in_metadata()
{
  readarray rows < data/library_metadata.txt

  for row_value in "${rows[@]}";
  do
    row_array=(${row_value});

		is_modified=${row_array[4]};
		artifact_id=${row_array[7]};
    if [ $is_modified == 0 ]; then
      echo $artifact_id >> data/modified_jars.txt
    else
      echo $artifact_id >> data/central_maven_jars.txt
    fi
  done

  if [ -f data/modified_jars.txt ]; then
      mv data/modified_jars.txt data/tmp.txt

      $(sort -u data/tmp.txt > data/modified_jars.txt)
      rm data/tmp.txt
      readarray rows < data/modified_jars.txt
      for row_value in "${rows[@]}";
      do
        row_array=(${row_value});
        artifact_id=${row_array[0]};
        grep -i "$artifact_id" data/library_metadata.txt | head -1 >> data/process_modified.txt
      done
  fi

  if [ -f data/central_maven_jars.txt ]; then

    mv data/central_maven_jars.txt data/tmp.txt
    $(sort -u data/tmp.txt > data/central_maven_jars.txt)
    rm data/tmp.txt
    readarray rows < data/central_maven_jars.txt
    for row_value in "${rows[@]}";
    do
      row_array=(${row_value});
      artifact_id=${row_array[0]};
      grep -i "$artifact_id" data/library_metadata.txt | head -1 >> data/process_central.txt
    done
  fi


}
generate_installer_file()
{
	echo "Started Running generate_installer_file()"

	url=$1
	arti_install=$2
  artifactory_port=$3
	if [ -z $url ]; then
		url='localhost'
	fi

  if [ -f data/process_modified.txt ]; then
    readarray rows < data/process_modified.txt
    for row_value in "${rows[@]}";
    do
      row_array=(${row_value});

  		file_name=${row_array[0]};
  		current_version=${row_array[2]};

  		group_id=${row_array[6]};
  		artifact_id=${row_array[7]};

  		if [ "$arti_install" -eq 0 ] ;
  		then

  			echo 'echo installing '$file_name' in local maven repo as '$artifact_id >> scripts/local_install.sh
  			echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId='$group_id' -DartifactId='$artifact_id' -Dversion='$current_version' -Dpackaging=jar  2> /dev/null	' >> scripts/local_install.sh;
  			echo 'if [ "$?" -ne 0 ] ; then' >> scripts/local_install.sh ;
  			echo 'echo "could not perform installation"; exit $rc' >> scripts/local_install.sh ;
  			echo "fi" >> scripts/local_install.sh ;
  			echo " " >> scripts/local_install.sh ;
  		fi
  		if [ "$arti_install" -eq 1 ];
  		then
  			echo 'echo installing '$file_name' in artifactory repo as '$artifact_id >> scripts/deploy_install.sh
  			echo 'mvn deploy:deploy-file -DrepositoryId=releases -Durl=http://'$url':'$artifactory_port'/artifactory/libs-release -Dfile='$file_name' -DgroupId='$group_id' -DartifactId='$artifact_id' -Dversion='$current_version' -Dpackaging=jar  2> /dev/null	' >> scripts/deploy_install.sh;
  			echo 'if [ "$?" -ne 0 ] ; then' >> scripts/deploy_install.sh ;
  			echo 'echo "could not perform installation"; exit $rc' >> scripts/deploy_install.sh ;
  			echo "fi" >> scripts/deploy_install.sh ;
  			echo " " >> scripts/deploy_install.sh ;
  		fi
  	done

  fi

	echo "Completed generate_installer_file()"
}

generate_pom()
{
	artifactory_url=$1
  artifactory_port=$2
	echo "Started Running generate_pom()"

	cat data/pom_stub.txt >> data/pom.xml

  temp=$( sed -i 's/artifactory_url/'"$artifactory_url"'/' data/pom.xml)
  temp=$( sed -i 's/artifactory_port/'"$artifactory_port"'/' data/pom.xml)
  temp=$( sed -i 's/artifact_id_proj/'"$artifact_id"'/' data/pom.xml)
  temp=$( sed -i 's/group_id_proj/'"$group_id"'/' data/pom.xml)

  if [ -f data/process_modified.txt ]; then
    readarray rows < data/process_modified.txt
    for row_value in "${rows[@]}";
  	do
      row_array=(${row_value});
  		current_version=${row_array[2]};
  		group_id=${row_array[6]};
  		artifact_id=${row_array[7]};

  		echo -e '\t\t<dependency>' >> data/pom.xml
			echo -e '\t\t\t<groupId>'$group_id'</groupId>' >> data/pom.xml
			echo -e '\t\t\t<artifactId>'$artifact_id'</artifactId>' >> data/pom.xml
			echo -e '\t\t\t<version>'$current_version'</version>'>> data/pom.xml
  		echo -e '\t\t</dependency>' >> data/pom.xml

  	done

  fi

  if [ -f data/process_central.txt ]; then
    readarray rows < data/process_central.txt
    for row_value in "${rows[@]}";
  	do
      row_array=(${row_value});
  		upgrade_version=${row_array[3]};
  		group_id=${row_array[6]};
  		artifact_id=${row_array[7]};

  		echo -e '\t\t<dependency>' >> data/pom.xml
      echo -e '\t\t\t<groupId>'$group_id'</groupId>' >> data/pom.xml
      echo -e '\t\t\t<artifactId>'$artifact_id'</artifactId>' >> data/pom.xml
      echo -e '\t\t\t<version>'$upgrade_version'</version>'>> data/pom.xml
      echo -e '\t\t</dependency>' >> data/pom.xml
  	done
  fi

	echo -e '\t</dependencies>' >> data/pom.xml
	echo -e '</project>' >> data/pom.xml
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

  cp data/temp_pom.xml data/pom.xml
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

generate_lib_removal()
{
  echo -e "Started generate_lib_removal()"
  if [ -f data/library_metadata.txt ]; then
    readarray rows < data/library_metadata.txt
    echo "is_git=\$1" >> scripts/library_removal.sh
    for row_value in "${rows[@]}";
  	do
      row_array=(${row_value});
      file_name=${row_array[0]};
      is_modified=${row_array[4]};
      if [ "$is_modified" -eq 1 ];
      then
        echo 'git rm '$file_name >> scripts/library_removal.sh
      fi
    done
  fi
  echo -e "Completed generate_lib_removal()"
}
printParameters()
{
	echo -e "\nRunning ant2Maven Script with below parameters \n"
	echo -e 'CompanyName =' $1', ProjectName = '$2', Artifactory_URL = '$3', Artifactory_Port = '$4', IsArtifactoryInstall = '$5', IsTestRun = '$6' \n'

}


main()
{
	if [ -z $comp_name ];
	then
		comp_name='com'
	fi

	if [ -z $proj_name ];
	then
		proj_name='proj'
	fi

	if [ -z $artifactory_url ];
	then
		artifactory_url='localhost'
	fi

  if [ -z $artifactory_port ];
	then
		artifactory_url='8081'
	fi

	if [ -z $arti_install ];
	then
		arti_install=1
	fi

	if [ -z $is_test ];
	then
		is_test=1
	fi

	printParameters $comp_name $proj_name $artifactory_url $artifactory_port $arti_install $isTest
	pre_setup
  populate_metadata
  process_ignore_list
  remove_duplicates_in_metadata
  generate_lib_removal
	#generate_pom $artifactory_url $artifactory_port
	#generate_installer_file $artifactory_url $arti_install $artifactory_port

	#mv data/pom.xml data/temp_pom.xml
	#install_dependencies $arti_install
	#run_gen_pom $is_test

  echo -e "Pom file generated at data/pom.xml"

}

main $comp_name $proj_name $artifactory_url $artifactory_port $arti_install $isTest
