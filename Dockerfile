FROM tomcat:10.1-jdk17-temurin

# Needed for TLS to Atlas
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates && rm -rf /var/lib/apt/lists/*

# Optional: git for convenience
# RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN rm -rf /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Explicit, sane Atlas params
ENV MONGO_URI="mongodb+srv://pmuller_db_user:uUJc84gJWAmxfs2g@cluster0.trig0cp.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0" \
    MONGO_DB="cmu95702" \
    MONGO_COLL="logs"

EXPOSE 8080
CMD ["catalina.sh", "run"]