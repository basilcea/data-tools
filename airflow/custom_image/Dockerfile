FROM apache/airflow:2.10.0
USER airflow
COPY requirements.txt /
RUN pip install --upgrade pip
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
RUN chmod 777 /opt/airflow/dags
RUN chmod 777 /opt/airflow/logs


