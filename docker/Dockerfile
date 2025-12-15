FROM openjdk:22-jdk-slim

# Set environment variables
ENV JETTY_HOME=/opt/jetty \
    JETTY_BASE=/opt/jetty_base \
    TELEGRAF_HOME=/opt/telegraf \
    PATH=$PATH:/opt/telegraf

# Create necessary directories
RUN mkdir -p $JETTY_HOME $JETTY_BASE $TELEGRAF_HOME /opt/downloads $JETTY_BASE/webapps

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    gnupg \
    apt-transport-https \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-buster-prod buster main" > /etc/apt/sources.list.d/microsoft.list' && \
    apt-get update && \
    apt-get install -y powershell && \
    rm /etc/apt/trusted.gpg.d/microsoft.gpg && \
    apt-get clean

# Download and set up Jetty
RUN curl -fsSL https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-home/12.0.9/jetty-home-12.0.9.zip -o /opt/downloads/jetty-home.zip && \
    echo "838E1DD769C8021C6DAA431770878E3B /opt/downloads/jetty-home.zip" | md5sum -c - && \
    unzip /opt/downloads/jetty-home.zip -d /opt/ && \
    mv /opt/jetty-home-12.0.9/* $JETTY_HOME && \
    rm -rf /opt/jetty-home-12.0.9 /opt/downloads/jetty-home.zip

# Download Jolokia
RUN curl -fsSL https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-agent-war-unsecured/2.0.2/jolokia-agent-war-unsecured-2.0.2.war -o $JETTY_BASE/webapps/jolokia.war && \
    echo "6678B95AECFA61215DECA4128A5AAA9B $JETTY_BASE/webapps/jolokia.war" | md5sum -c -

RUN cd $JETTY_BASE && \
    java -jar $JETTY_HOME/start.jar --add-modules=server,http,ee10-deploy && \
    java -jar $JETTY_HOME/start.jar --add-module=demos

# Download and set up Telegraf
RUN curl -fsSL https://dl.influxdata.com/telegraf/releases/telegraf-1.30.3_linux_amd64.tar.gz -o /opt/downloads/telegraf.tar.gz && \
    echo "e3b2dca796f461633f44e67803f1286dc70f619f3613c8369da62112802c51ca  /opt/downloads/telegraf.tar.gz" | sha256sum -c - && \
    tar -xzf /opt/downloads/telegraf.tar.gz -C /opt/ && \
    mv /opt/telegraf-1.30.3/* $TELEGRAF_HOME && \
    rm -rf /opt/telegraf-1.30.3 /opt/downloads/telegraf.tar.gz

# Expose ports for Jetty (8080) and Telegraf (8125)
EXPOSE 8080 8125

COPY entrypoint.sh /opt/entrypoint.sh
COPY supervisord.conf /opt/supervisord.conf
COPY supervisord_monitoring_only.conf /opt/supervisord_monitoring_only.conf

COPY BoomiProcesses.ps1 $TELEGRAF_HOME/BoomiProcesses.ps1
COPY telegraf-base.conf.template /opt/telegraf-base.conf.template
COPY telegraf-input.conf.template /opt/telegraf-input.conf.template
COPY telegraf_boomi_processes.conf $TELEGRAF_HOME/telegraf_boomi_processes.conf
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
