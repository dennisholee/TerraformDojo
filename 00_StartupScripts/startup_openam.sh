#!/bin/bash

# Update libraries
sudo apt-get update

# Install packages:
# - JDK
# - unzip
sudo apt-get -y install unzip openjdk-11-jdk

# Install tomcat

sudo useradd tomcat
sudo groupadd tomcat
sudo usermod -a -G tomcat tomcat

sudo tomcat
wget http://apache.01link.hk/tomcat/tomcat-9/v9.0.22/bin/apache-tomcat-9.0.22.tar.gz
tar xzf apache-tomcat-9.0.22.tar.gz
sudo mv apache-tomcat-9.0.22 /usr/local/apache-tomcat9

# Initialize environment variables
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> ~/.bashrc
echo "export CATALINA_HOME=/usr/local/apache-tomcat9" >> ~/.bashrc
echo "export JAVA_OPT=${JAVA_OPT} -Xms 2048m -Xmx 2048m" > /usr/local/apache-tomcat9/bin/setenv.sh
