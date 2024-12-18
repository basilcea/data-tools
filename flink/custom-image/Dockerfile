FROM flink:1.17.2

RUN  apt-get update \
  && apt-get install -y wget \
  openjdk-11-jdk-headless \
  && rm -rf /var/lib/apt/lists/*

RUN wget -P /opt/flink/lib https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/1.17.2/flink-sql-connector-kafka-1.17.2.jar
RUN wget -P /opt/flink/lib https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-rabbitmq/3.0.1-1.17/flink-sql-connector-rabbitmq-3.0.1-1.17.jar
RUN wget -P /opt/flink/lib https://repo.maven.apache.org/maven2/org/apache/flink/flink-python/1.17.2/flink-python-1.17.2.jar
RUN wget -P /opt/flink/lib https://repo.maven.apache.org/maven2/org/apache/flink/flink-connector-debezium/3.1.1/flink-connector-debezium-3.1.1.jar
# install python3 and pip3
RUN apt-get update -y && \
apt-get install -y python3 python3-pip python3-dev && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/python3 /usr/bin/python

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64

# install PyFlink
RUN pip3 install apache-flink==1.17.2

USER flink

RUN mkdir /opt/flink/pyfiles