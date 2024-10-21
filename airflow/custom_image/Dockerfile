FROM apache/airflow:2.10.0
USER root
ARG AIRFLOW_UID=65533

RUN usermod -u ${AIRFLOW_UID} airflow && \
    chown -R airflow:root /opt/airflow

USER airflow
# Update the GID of directories and make them writable by the group
COPY custom_image/requirements.txt /
RUN pip install --upgrade pip
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
RUN chmod 770 /opt/airflow/dags
RUN chmod 770 /opt/airflow/logs


