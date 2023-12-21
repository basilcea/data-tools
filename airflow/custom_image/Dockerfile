FROM apache/airflow:2.7.1
COPY requirements.txt /
RUN pip install --upgrade pip
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt

# To Try from
# multistage build from the our own built dbt docker image in azure registry and then from apache airflow
# from 	oaftech.azurecr.io/oneacrefund/dbt:1
# from apache/airflow:2.7.1