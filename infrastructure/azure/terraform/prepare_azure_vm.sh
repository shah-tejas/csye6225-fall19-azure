#! /bin/sh
sudo touch /opt/tomcat/bin/setenv.sh
sudo chmod 777 /opt/tomcat/bin/setenv.sh
sudo echo 'export JAVA_OPTS="$JAVA_OPTS -Dspring.datasource.url='${azure_db_endpoint}'"' >> /opt/tomcat/bin/setenv.sh
sudo echo 'JAVA_OPTS="$JAVA_OPTS -Dspring.datasource.username='${azure_db_username}'"' >> /opt/tomcat/bin/setenv.sh
sudo echo 'JAVA_OPTS="$JAVA_OPTS -Dspring.datasource.password='${azure_db_password}'"' >> /opt/tomcat/bin/setenv.sh
sudo systemctl restart tomcat
