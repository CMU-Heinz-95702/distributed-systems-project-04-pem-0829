# FROM tomcat:9.0-jdk17-temurin
FROM tomcat:10.1-jdk17-temurin

# optional: keep git inside the devcontainer
RUN apt-get update && apt-get install -y git ca-certificates && rm -rf /var/lib/apt/lists/*

# deploy only our app
RUN rm -rf /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war

# env for Mongo
ENV MONGO_URI="mongodb+srv://pmuller_db_user:uUJc84gJWAmxfs2g@cluster0.trig0cp.mongodb.net/?appName=Cluster0" \
    MONGO_DB="cmu95702" \
    MONGO_COLL="logs"

EXPOSE 8080
CMD ["catalina.sh", "run"]