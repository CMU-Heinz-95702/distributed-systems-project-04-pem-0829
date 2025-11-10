FROM tomcat:10.1-jdk17-temurin

# Needed for TLS to Atlas
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates && rm -rf /var/lib/apt/lists/*

# Optional: git for convenience
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN rm -rf /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Explicit, sane Atlas params
ENV MONGO_URI="mongodb://pmuller_db_user:uUJc84gJWAmxfs2g@\
ac-lalwbg5-shard-00-00.trig0cp.mongodb.net:27017,\
ac-lalwbg5-shard-00-01.trig0cp.mongodb.net:27017,\
ac-lalwbg5-shard-00-02.trig0cp.mongodb.net:27017/?retryWrites=true&w=majority&tls=true&authMechanism=SCRAM-SHA-1" \
    MONGO_DB="cmu95702" \
    MONGO_COLL="logs"

EXPOSE 8080
CMD ["catalina.sh", "run"]