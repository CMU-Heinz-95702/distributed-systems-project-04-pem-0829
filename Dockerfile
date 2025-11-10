# Tomcat 10 + JDK 17
FROM tomcat:10.1-jdk17-temurin

# Tools you installed while debugging: git, curl, unzip, TLS roots
# Also add mongosh for quick connectivity checks
ARG MONGOSH_VER=2.3.7
RUN set -eux; \
  apt-get update && \
  apt-get install -y --no-install-recommends git curl unzip ca-certificates && \
  update-ca-certificates && \
  curl -fsSL https://downloads.mongodb.com/compass/mongosh-${MONGOSH_VER}-linux-x64.tgz \
    | tar -xz -C /opt && \
  ln -s /opt/mongosh-${MONGOSH_VER}-linux-x64/bin/mongosh /usr/local/bin/mongosh && \
  rm -rf /var/lib/apt/lists/*

# Enforce TLS 1.2 for MongoDB drivers
ENV JAVA_OPTS="-Djdk.tls.client.protocols=TLSv1.2 -Dhttps.protocols=TLSv1.2"

# Clean default apps and deploy your WAR
RUN rm -rf /usr/local/tomcat/webapps/*
COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Mongo env
ENV MONGO_URI="mongodb+srv://pmuller_db_user:uUJc84gJWAmxfs2g@cluster0.6yieb2k.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0" \
    MONGO_DB="cmu95702" \
    MONGO_COLL="logs"

# Simple liveness check
HEALTHCHECK --interval=30s --timeout=3s --retries=5 \
  CMD curl -fsS http://localhost:8080/ || exit 1

EXPOSE 8080
CMD ["catalina.sh","run"]