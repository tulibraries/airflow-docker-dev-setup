# Shared Docker Development Setup for Airflow DAGs


This repo contains all of the setup needed to run airflow in docker, mount your local dag repo into the containers that need it, and allow you to develop dags hopefully quickly!


## Expected Setup

This repo expects:

* to be a git submodule living in the root of your dags repo. 
* dag files are in a directory in the top level.
* a `local.env` file with `DAG_DIR=some_name` with the name of the directory containing your dag files.


## Setup

In the root of you dags repository, run `git submodule add git@github.com:tulibraries/airflow-docker-dev-setup docker`, and then commit the changes to .gitmodules and the new `docker` directory that has just been created.

Next, in the root of your dags repository, create a file called `local.env`. Add the line `DAG_DIR=my_dag_dir` with the actual name of the directory in the root of the repo containing your dag files. If your dags do any python import statements, this directory name needs to match the top level package in those import statements.

Finally, you should ensure that you have set the following environment varibles, `TUPSFTP_PASSWORD`, `WORKER_SSH_KEY_PATH`, `TUP_ACCOUNT_NAME`, `TUP_SSH_KEY_PATH`, and `TUP_SFTP_ACCOUNT_NAME`. For example:

    export TUPSFTP_PASSWORD="REINDEER FLOTILLA"
    export WORKER_SSH_KEY_PATH="/home/flynn/.ssh/id_rsa"
    export TUP_ACCOUNT_NAME="flynn_the_deployer"
    export TUP_SSH_KEY_PATH="/usr/local/airflow/.ssh/flynn_the_deployer"
    export TUP_SFTP_ACCOUNT_NAME="flynnsplace"

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

#### Reload Docker Instances

If you change something in the docker setup, e.g. an airflow worker build step, you may want to restart the docker instances (restarts, does not destroy and rebuild):

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

Run shell in Airflow Worker instance:

```
 $ make tty-worker
```

Run shell in Airflow Webserver instance:

```
$ make tty-webserver
```

Run shell in Airflow Scheduler instance:

```
$ make tty-scheduler
```

### Start Bash as Root in Given Docker Instance

Run shell as root in Airflow Worker instance:

```
$ make tty-root-worker
```

Run shell as root in Airflow Webserver instance:

```
$ make tty-root-webserver
```
Run shell as root in Airflow Scheduler instance:

```
$ make tty-root-scheduler
```


