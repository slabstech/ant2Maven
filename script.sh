#!/bin/sh
#Script to generate pom dependencies

pre_setup()
{
	chmod +x cleanupfiles.sh
	sh cleanupfiles.sh

	find . -name '*.jar' | sed -e 's/\.\///' > filelist.txt

	cat pom_stub.txt >> new_pom.xml
	sort -u filelist.txt
}

generate_pom()
{
	echo "JarName \t CurrentVersion \t UpgradeVersion \t IsModified \t IsUpgradable">> library_metadata.txt

	comp_name='sample'
	for file_name in `cat filelist.txt`;
	do
		isModified=`jar_modification $file_name`
		isUpgradable=`jar_upgradable $file_name`
		fname=$(basename $file_name);
		if [ -d META-INF ]
		then
			rm -rf META-INF
		fi
		jar -xf $file_name META-INF/MANIFEST.MF
		version=`grep "Implementation-Version" META-INF/MANIFEST.MF | cut -d ':' -f2 | xargs`
		#jar_vendor=`grep "Implementation-Vendor-Id" META-INF/MANIFEST.MF | cut -d ':' -f2 | xargs`
		jar_vendor=$(echo $fname|sed -e 's/\.jar//') ;
		echo 'mvn -q install:install-file -Dfile='$file_name' -DgroupId=com.'$comp_name'.'$jar_vendor' -DartifactId='$comp_name'-lib-'$jar_vendor' -Dversion=1.0 -Dpackaging=jar ' >>install.txt;
		echo " " >> install.txt ;
	  echo $fname'\t '$version' \t '$isModified' \t '$isUpgradable >> library_metadata.txt
		echo '\t\t<dependency>' >> new_pom.xml
		echo '\t\t\t<groupId>com.'$comp_name'.'$jar_vendor'</groupId>' >> new_pom.xml
		echo '\t\t\t<artifactId>'$comp_name'-lib-'$jar_vendor'</artifactId>' >> new_pom.xml
		echo '\t\t\t<version>1.0</version>'>> new_pom.xml
		echo '\t\t</dependency>' >> new_pom.xml

	done;

	echo '</dependencies>
		</project>' >> new_pom.xml

}

install_dependencies(){
	mv install.txt install.sh

	chmod +x install.sh

	sh install.sh
}

run_gen_pom()
{
	mv new_pom.xml example/pom.xml
	cd example
	mvn -q clean install
	if [ "$?" -ne 0 ] ; then
	  echo 'could not perform installation'; exit $rc
	fi
	if [ "$?" -eq 0 ] ; then
	  echo 'Maven project compiled successfully'; exit $rc
	fi

	cd ..
}

jar_modification()
{
	#echo 'Checking '$1' for local modifications'
	#return 0
	echo "True"
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
