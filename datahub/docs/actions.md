## Superset Action

This action manages datasets in
[Apache Superset](https://github.com/apache/superset). It currently
provides the following functionality:
- Creates datasets in Superset whenever new datasets are ingested
  into Datahub
- Creates a link in Datahub on the dataset for browsing the dataset
  in Superset
- Creates a link in Datahub on the dataset requesting for access to
  the dataset in Superset

### Configuration

The following are the custom configuration parameters provided by
this action.

| Parameter| Default | Description|
|-----------|---------|-----------|
| superset.url | | URL to superset (eg. http://localhost:8088)|
| superset.username | |  |
| superset.password | | |
| superset.provider | db | Authentication mechanism for the user (API access in superset is limited to db users only, this is here for future proofing) |
| connections | | An array comprising {name, platform, catalog}|
| connections[i].name | | Name of a database connection in Superset |
| connections[i].platform | | Database server identifier (e.g. postgres, mssql) |
| connections[i].catalog | | The name of the database connected to (e.g. OAF_SHARED_DIMENSIONS) |

The following is an example configuration:

```yaml
name: superset
source:
  type: kafka
  config:
    connection:
      bootstrap: ${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}
      schema_registry_url: ${SCHEMA_REGISTRY_URL:-http://localhost:8081}
filter:
  event_type: EntityChangeEvent_v1
action:
  type: oaf_datahub.actions:SupersetAction
  config:
    superset:
      url: ${SUPERSET_URL:-http://localhost:8088}
      username: ${SUPERSET_USER:-admin}
      password: ${SUPERSET_USER:-admin}
      connections:
        - name: DatahubTest
          platform: postgres
          catalog: datahub_test
    datahub:
      url: ${DATAHUB_URL:-http://localhost:8080}
```

### How this action works

1. Receives a recently created dataset from Datahub
2. Extracts the fully qualified name of the dataset (ie.
  `<catalog>.<schema>.<table name>`) and platform of the dataset
3. Fetches a connection in the configuration that matches this
  dataset using the catalog and platform from above
4. Checks if Superset has the connection (exits if not)
5. Checks if Superset already has the dataset (go to 7 if it exists)
6. Creates the dataset
7. Add links to the dataset in Datahub

