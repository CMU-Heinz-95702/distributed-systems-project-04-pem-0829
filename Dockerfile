FROM tomcat:10.1-jdk17-temurin

# TLS roots for Atlas
RUN apt-get update \
 && apt-get install -y ca-certificates \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Deploy only our app
RUN rm -rf /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Mongo env (fill password)
ENV MONGO_URI="mongodb+srv://pmuller_db_user:uUJc84gJWAmxfs2g@cluster0.6yieb2k.mongodb.net/?appName=Cluster0" \
    MONGO_DB="cmu95702" \
    MONGO_COLL="logs"

EXPOSE 8080
CMD ["catalina.sh","run"]