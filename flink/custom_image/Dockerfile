FROM flink:1.17.2
RUN wget /opt/flink/lib https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/1.17.2/flink-sql-connector-kafka-1.17.2.jar
RUN wget /opt/flink/lib https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-rabbitmq/3.0.1-1.17/flink-sql-connector-rabbitmq-3.0.1-1.17.jar

# install python3 and pip3
RUN apt-get update -y && \
apt-get install -y python3 python3-pip python3-dev && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/python3 /usr/bin/python

# install PyFlink
RUN pip3 install apache-flink==1.17.2