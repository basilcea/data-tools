
FROM apache/airflow:2.10.0
USER root
ARG AIRFLOW_UID=65533

RUN mkdir /opt/airflow/snowflake
RUN mkdir /opt/airflow/mssql

RUN usermod -u ${AIRFLOW_UID} airflow && \
    chown -R airflow:root /opt/airflow && \
    chown -R airflow:root /opt/airflow/dags  && \
    chown -R airflow:root /opt/airflow/snowflake && \
    chown -R airflow:root /opt/airflow/mssql

USER airflow
# Update the GID of directories and make them writable by the group
COPY requirements.txt /
RUN pip install --upgrade pip
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
# RUN pip install -i https://pypi.cloud.soda.io "soda-sqlserver"
# RUN pip install -i https://pypi.cloud.soda.io "soda-postgres"
# RUN pip install -i https://pypi.cloud.soda.io "soda-snowflake"
# RUN pip install -i https://pypi.cloud.soda.io "soda-dbt[ver16]"

RUN chmod 770 /opt/airflow/dags
RUN chmod 770 /opt/airflow/logs



