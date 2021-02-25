# Shared Docker Development Setup for Airflow DAGs


This repo contains all of the setup needed to run airflow in docker, mount your local dag repo into the containers that need it, and allow you to develop dags hopefully quickly!


## Expected Setup

This repo expects:

* to be a git submodule living in the root of your dags repo. 
* dag files are in a directory in the top level.
* a `local.env` file with `DAG_DIR=some_name` with the name of the directory containing your dag files.


## Setup

If you are starting from an existing DAG, see [Setup from Existing DAG Git Repo](#FromGitModule) below.

First, in the root of you dags repository, run `git submodule add git@github.com:tulibraries/airflow-docker-dev-setup docker`, and then commit the changes to .gitmodules and the new `docker` directory that has just been created.

Next, in the root of your dags repository, create a file called `local.env`. Add the line `DAG_DIR=my_dag_dir` with the actual name of the directory in the root of the repo containing your dag files. If your dags do any python import statements, this directory name needs to match the top level package in those import statements.

## Usage

To use the docker setup, `cd` into the `docker` directory. This contains the `docker-compose.yml` and some other docker configurations, a `docker-requirement.txt` for pypi packages you want installed on the container, and a Makefile defining some useful commands.

```

$ make up

```

This spins up an Airflow stack using Postgres for the metadata database; Celery, Redis & Flower for job management; CeleryExecutor, Scheduler, Web-Server and Worker Airflow services; and mounting the local `dags` directory as the Airflow stack's DAGs directory. That DAGs directory has cob_datapipeline and manifold_airflow_dags cloned into it if these subdirectories do not already exist. This will also create some known Variables and Connections, based off of `data/example-variables.json` (the task copies this into `data/variables.json` if that file doesn't exist, then loads variables into Airflow from there).

Give this up to 1 minute to start up. You can check the Airflow web-server health-check state by running:

```
$ docker-compose -p infra ps
```

### Common Problem: "Variable import failed"

During `make up` you may encounter several erros similar to:

```
   Variable import failed: ProgrammingError('(psycopg2.ProgrammingError) relation "variable" does not exist...
```

You may need to extend the build target's sleep time in `airflow-docker-dev-setup/Makefile` to 120 seconds to allow the MySQL container more time to start up before continuing on to subsequent commands.

Edit `airflow-docker-dev-setup/Makefile`, search for the `build` target and edit the `sleep` command's time from `40` to `120`.

```
build:
       @echo "Building airflow containers, networks, volumes"
       docker-compose pull
       docker-compose -p 'infra' up --build -d
       sleep 40 # <== Change from 40 to 120
       @echo "airflow running on http://127.0.0.1:8010"
```

### <<a id="FromGitModule"></a>Setup From Existing DAG Git Repo

If you clone your DAG from a Git repository, you will need create and update this Git Submodule from your DAG's root directory:

```
	git submodule init
	git submodule update
```

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
