FROM eclipse-temurin:21-jdk

SHELL ["/bin/bash", "-c"]

WORKDIR /opt/aem

# Install bash for troubleshooting
RUN apt-get update && apt-get install -y bash bash-completion && rm -rf /var/lib/apt/lists/*

# Copy from root-level install folder in build context
COPY install/aem-quickstart.jar ./aem-quickstart.jar
COPY install/cif-cloud-ready-feature-pkg-2024.09.05.00-cq-commerce-addon-authorfar.far ./install/cif.far

# Also install WKND author content package!
# COPY install/wknd-author-content.zip ./install/


EXPOSE 4502 30303

# Enable remote debugging on port 30303
CMD ["sh", "-c", "\
    echo 'Starting AEM in AUTHOR mode on port 4502 with DEBUG enabled' && \
    java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:30303 \
    -Xmx2048m -XX:MaxMetaspaceSize=512m \
    -jar aem-quickstart.jar -r author -port 4502 -nofork \
    "]