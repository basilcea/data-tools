from pyflink.table import EnvironmentSettings, TableEnvironment
from pyflink.table.expressions import col

# 1. create a TableEnvironment
env_settings = EnvironmentSettings.in_streaming_mode()
table_env = TableEnvironment.create(env_settings)

# 2. create source Table
table_env.execute_sql("""
    CREATE TABLE datagen (
        id INT,
        data STRING
    ) WITH (
        'connector' = 'datagen',
        'fields.id.kind' = 'sequence',
        'fields.id.start' = '1',
        'fields.id.end' = '10'
    )
""")

# 3. create sink Table
table_env.execute_sql("""
    CREATE TABLE print (
        id INT,
        data STRING
    ) WITH (
        'connector' = 'print'
    )
""")

# 4. query from source table and perform calculations
# create a Table from a Table API query:
source_table = table_env.from_path("datagen")
# or create a Table from a SQL query:
# source_table = table_env.sql_query("SELECT * FROM datagen")

result_table = source_table.select(col("id") + 1, col("data"))

# 5. emit query result to sink table
# emit a Table API result Table to a sink table:
result_table.execute_insert("print")
# or emit results via SQL query:
# table_env.execute_sql("INSERT INTO print SELECT * FROM datagen").wait()