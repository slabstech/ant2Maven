if [ -f filelist.txt]
	rm filelist.txt
fi

find . -name '*.jar' | sed -e 's/\.\///' > filelist.txt

if [ -f install.txt ]
	rm install.txt 
fi

if [ -f new_pom.xml ]
	rm new_pom.xml
fi

echo'
<project xmlns="http://maven.apache.org/POM/4.0.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>pace</groupId>
	<artifactId>pace</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
	</properties>
	<build>
		<!-- <sourceDirectory>build/testclasses</sourceDirectory> <testSourceDirectory>build/tests</testSourceDirectory> -->
		<sourceDirectory>src/java</sourceDirectory>
		<testSourceDirectory>src/test</testSourceDirectory>
		<resources>
			<resource>
				<directory>build/testclasses</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
			<resource>
				<directory>build/gensrc</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
			<resource>
				<directory>build/classes</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
			<resource>
				<directory>src/java</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
		</resources>
		<testResources>
			<testResource>
				<directory>build/tests</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</testResource>
			<testResource>
				<directory>src/test</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</testResource>
		</testResources>
		<plugins>
			<plugin>
				<artifactId>maven-compiler-plugin</artifactId>
				<version>3.7.0</version>
				<configuration>
					<source>1.8</source>
					<target>1.8</target>
					<fork>true</fork>
					<executable>C:\Program Files\Java\jdk1.8.0_171\bin\javac.exe</executable>

				</configuration>
			</plugin>
		</plugins>
	</build>
	<dependencies>
'> new_pom.xml

sort -u filelist.txt

comp_name='sample'
for i in `cat filelist.txt`; 
do 
	fname=$(basename $i); 
	tmp=$(echo $fname|sed -e 's/\.jar//') ;
	echo $'mvn install:install-file -Dfile='$i' -DgroupId=com.'$comp_name'.'$tmp' -DartifactId='$comp_name'-lib-'$tmp' -Dversion=1.0 -Dpackaging=jar ' >>install.txt;  
	echo " " >> install.txt ;
	
	echo '<dependency>' >> new_pom.xml
	echo '<groupId>com.'$comp_name'.'$tmp'</groupId>' >> new_pom.xml
	echo '<artifactId>'$comp_name'-lib-'$tmp'</artifactId>' >> new_pom.xml
	echo '<version>1.0</version>'>> new_pom.xml
	echo '</dependency>' >> new_pom.xml	
	
done;

echo '
	</dependencies>
	</project>' >> new_pom.xml


mv install.txt install.sh

chmod +x install.sh

sh install.sh


