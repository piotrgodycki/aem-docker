FROM eclipse-temurin:21-jdk

SHELL ["/bin/bash", "-c"]

WORKDIR /opt/aem

# Install additional packages (Temurin images are Ubuntu-based)
RUN apt-get update && apt-get install -y bash bash-completion && rm -rf /var/lib/apt/lists/*

# Copy from root-level install folder in build context
COPY install/aem-quickstart.jar ./aem-quickstart.jar
COPY install/cif-cloud-ready-feature-pkg-2024.09.05.00-cq-commerce-addon-publishfar.far ./install/cif.far

EXPOSE 4503

# Enable remote debugging on port 30304
CMD ["sh", "-c", "\
    echo 'Starting AEM in PUBLISH mode on port 4503 with DEBUG enabled' && \
    java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:30304 \
    -Xmx2048m -XX:MaxMetaspaceSize=512m \
    -jar aem-quickstart.jar -r publish -port 4503 -nofork \
    "]
