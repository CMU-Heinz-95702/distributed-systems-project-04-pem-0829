FROM tomcat:9.0-jdk17-temurin
# keep Tomcat clean and only deploy our app
RUN rm -rf /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
