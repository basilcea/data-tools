# OAF Datahub

Collection of custom utilities for Datahub by OAF. Repository contains
the following Datahub assets:

- [Actions](./docs/actions.md)

## Getting started

### Requirements

- Python 3.10 or higher
- [Poetry](https://python-poetry.org/)
- Docker
- At least 8GB RAM (on Windows/WSL 16GB or more might be required)

### Development environment setup

All commands below assume you are located at the root of this repository.

- Install dependencies

    ```sh
    $ poetry install
    ```

- Set up a local instance of datahub

    ```sh
    $ poetry shell
    $ DATAHUB_VERSION=v0.9.0 datahub docker quickstart # This is how datahub is started
    ```

- Optionally set up superset

    ```sh
    $ git clone https://github.com/apache/superset
    $ git checkout v2.0.0
    $ TAG=2.0.0 docker-compose -f docker-compose-non-dev.yml up # Username:password == admin:admin
    ```

NOTE: Poetry creates a [virtualenv](https://docs.python.org/3/tutorial/venv.html)
with this project's dependencies at
`~/.cache/pypoetry/virtualenvs/oaf-datahub-<some-random-string>`. You need to
configure your editor to use that `virtualenv`. In
[vscode](https://code.visualstudio.com/), you can set the virtualenv
by hitting `CTRL-SHIFT-p` and then typing `Python: Select Interpreter`.
It's also recommended to install the
[mypy](https://marketplace.visualstudio.com/items?itemName=matangover.mypy)
plugin in vscode and setting the Python linter to something else that
isn't mypy. For example pylint can be configured by doing
`CTRL-SHIFT-p > Python: Select Linter > Pylint`.

### Building actions

- Learn about running and building actions [here](https://datahubproject.io/docs/actions/)
- To run actions in this project, you need to:
    1. Be at the root of this project
    2. Be in a virtualenv activated by running `poetry shell`
    3. Specify the action in your action configuration file
       as `oaf_datahub.actions.<action's module name>:<action's class name>`
       (see [this example](./examples/actions/superset.action.yaml))
- Documentation for the actions in this repository is [here](./docs/actions.md)

