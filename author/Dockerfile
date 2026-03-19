FROM eclipse-temurin:21-jdk

SHELL ["/bin/bash", "-c"]

WORKDIR /opt/aem

# Install bash for troubleshooting
RUN apt-get update && apt-get install -y bash bash-completion && rm -rf /var/lib/apt/lists/*

# Copy from root-level install folder in build context
COPY install/aem-quickstart.jar ./aem-quickstart.jar

# Pre-unpack the quickstart JAR during build (saves ~5 min on first start)
RUN java -jar aem-quickstart.jar -unpack -r author -port 4502 && \
    rm -f aem-quickstart.jar

# Install CIF package into the install directory
COPY install/cif-cloud-ready-feature-pkg-2025.07.22.00-cq-commerce-addon-authorfar.far ./crx-quickstart/install/cif.far

# Install wcm.io Context-Aware Configuration
COPY install/io.wcm.caconfig.editor.package-1.16.10.zip ./crx-quickstart/install/
COPY install/io.wcm.caconfig.extensions-1.11.0.jar ./crx-quickstart/install/

# Also install WKND author content package!
# COPY install/wknd-author-content.zip ./crx-quickstart/install/

EXPOSE 4502 30303

# Enable remote debugging on port 30303
CMD ["sh", "-c", "\
    echo 'Starting AEM in AUTHOR mode on port 4502 with DEBUG enabled' && \
    java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:30303 \
    -Xmx4096m -XX:MaxMetaspaceSize=1024m \
    -jar crx-quickstart/app/cq-quickstart-*-standalone-quickstart.jar \
    -r author -port 4502 -nofork -c crx-quickstart \
    "]