# Shared Docker Development Setup for Airflow DAGs


This Git repository contains all of the setup needed to run airflow in docker, mount your local DAG repo into the containers that need it, and allow you to develop DAGs hopefully quickly!


## Expected Setup

This repo expects:

* To be a Git submodule residing in the root of your DAG's Git repoitory. 
* The DAG project directory structure:
```
example_airflow_dags/
├── Makefile
├── Pipfile
├── Pipfile.lock
├── README.md
├── docker
│   ├── Makefile
│   ├── README.md
│   ├── bin
│   │   └── start.sh
│   ├── data
│   │   └── ...
│   ├── docker-compose.yml
│   ├── docker-requirements.txt
│   ├── example-variables.json
│   └── worker
│       └── dockerfile
├── local.env
├── example_dags
│   ├── example_dag_1.py
│   ├── example_dag_2.py
│   └── ...
├── tests
│   ├── conftest.py
│   ├── example_dag_1_test.py
│   ├── example_dag_2_test.py
│   └── ...
└── variables.json
```
* The `local.env` file contains the line `DAG_DIR=some_name` with the name of the directory containing your DAG files.


## Setup

Note: If you are starting from an existing DAG with this Git repository already contained in the `gitmodules` file, see [Setup from Existing DAG Git Repository](#FromGitModule) below instead.

Add this Git repository as a Git submodule to the root of the DAG you are developing.

```
git submodule add git@github.com:tulibraries/airflow-docker-dev-setup docker`
```

Cmmit the changes to .gitmodules and the new `docker` directory that has just been created.

```
git add .gitsubmodules docker
```

In the root of your dags repository, create a file called `local.env`. add the line `DAG_DIR=my_dag_dir` with the actual name of the directory in the root of the repo containing your dag files. Following the example directory tree, the line would be: `DAG_DIR=example_dags` If your dags python code has mport statements, this DAG directory name must match the top level package in those import statements


### <a id="FromGitModule"></a>Setup From Existing DAG Git Repository

If you cloned your DAG from a Git repository and it already has the `airflow-docker-dev-setup` Git submodule, you will need to perform the following commands to complete the dev container installation process.  From your DAG's root directory:

```
	git submodule init
	git submodule update
```

Then change directories to the docker dev environment `cd docker`


## Usage

To run Airflow in within a containerized dev environment, go into the `docker` directory: `cd docker `. This directory contains the `docker-compose.yml`, docker configurationss, and a `docker-requirement.txt` for pypi packages you want installed on the container, and a Makefile defining some useful commands.

```

$ make up

```

This spins up an Airflow stack using PostgreSQL for the metadata database; Celery, Redis & Flower for job management; CeleryExecutor, Scheduler, Web-Server and Worker Airflow services; and mounting the local `dags` directory as the Airflow stack's DAGs directory. That DAGs directory has cob_datapipeline and manifold_airflow_dags cloned into it if these subdirectories do not already exist. This will also create some known Variables and Connections, based off of `data/example-variables.json` (the task copies this into `data/variables.json` if that file doesn't exist, then loads variables into Airflow from there).

Give this up to 1 minute to start up. You can check the Airflow web-server health-check state by running:

```
$ docker-compose -p infra ps
```

**NOTE** You may encounter a `Variale Import Failed` error which will prevent the proper startup of all the Docker containers.  This is a common problem.  See [Variable Import Failed](#VariableImportFailed) below and re-run `make up`

### Reload Docker Instances

If you change anything in the docker setup, e.g. an airflow worker build step, you may need to restart the docker instances (restarts will not destroy and rebuild the Docker containers and images):

```
$ make reload
```

#### Stop Local Airflow Stack (but do not delete)

```
 $ make stop
```

This will stop but not delete the Airflow docker stack, for ease of restart if you want to continue using these instances.

#### Delete Local Airflow Stack

```
 $ make down
```

#### Start Bash in Given Docker Instance

Run command shell in Airflow Worker instance:

```
 $ make tty-worker
```

Run command shell in Airflow Webserver instance:

```
$ make tty-webserver
```

Run command shell in Airflow Scheduler instance:

```
$ make tty-scheduler
```

### Start Bash as Root in Given Docker Instance

Run command shell as root in Airflow Worker instance:

```
$ make tty-root-worker
```

Run command shell as root in Airflow Webserver instance:

```
$ make tty-root-webserver
```
Run command shell as root in Airflow Scheduler instance:

```
$ make tty-root-scheduler
```
## <a id="VariableImportFailed"></a>Common Problem: "Variable Import Failed"

During `make up` you may encounter several erros similar to:

```
   Variable import failed: ProgrammingError('(psycopg2.ProgrammingError) relation "variable" does not exist...
```

Extend the build target's sleep time in `airflow-docker-dev-setup/Makefile` to allow the database container more time to start up before continuing on to subsequent commands.  Edit `airflow-docker-dev-setup/Makefile`, search for the `build` target and edit the `sleep` command's time from `40` to `120`.

```
build:
       @echo "Building airflow containers, networks, volumes"
       docker-compose pull
       docker-compose -p 'infra' up --build -d
       sleep 120
       @echo "airflow running on http://127.0.0.1:8010"
```

