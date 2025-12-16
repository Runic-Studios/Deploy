# Dockerfile.java
FROM registry.runicrealms.com/agents/agent-base:latest

# Install Amazon Corretto 21 (JDK 21)
RUN wget -nv https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.deb && \
    dpkg -i amazon-corretto-21-x64-linux-jdk.deb || true && \
    apt-get update && apt-get install -y -f && \
    rm amazon-corretto-21-x64-linux-jdk.deb && \
    java -version

ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
ENV PATH="$JAVA_HOME/bin:${PATH}"

WORKDIR /workspace
