FROM httpd:2.4

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

# Install bash for troubleshooting
RUN apt-get update && apt-get install -y bash bash-completion && rm -rf /var/lib/apt/lists/*

# # Install Adobe dispatcher tools (module, validation scripts, etc.)
# RUN mkdir -p ./dispatcher-tools

# COPY aem-sdk-dispatcher-tools-2.0.235-unix.sh ./dispatcher-tools.sh
# RUN chmod a+x dispatcher-tools.sh && \
#     ./dispatcher-tools.sh && \
#     rm -f dispatcher-tools.sh


# Copy your Adobe SDK dispatcher configuration (after extraction)
COPY dispatcher-sdk-2.0.235/src/conf.d /etc/httpd/conf.d
COPY dispatcher-sdk-2.0.235/src/conf.dispatcher.d /etc/httpd/conf.dispatcher.d

EXPOSE 80

CMD ["httpd-foreground"]