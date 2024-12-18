FROM bitnami/spark

USER root

# Install curl (if not already installed)
RUN install_packages curl
USER 1001
RUN curl https://repo1.maven.org/maven2/io/okdp/okdp-spark-auth-filter/1.2.2/okdp-spark-auth-filter-1.2.2.jar --output /opt/bitnami/spark/jars/okdp-spark-auth-filter-1.2.2.jar




