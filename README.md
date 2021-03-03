# Shared Docker Development Setup for Airflow DAGs


The `airflow_docker_dev_setup` project provides a means to facilitate local DAG development in a containerized Docker environment.


## Setup

To use this tool, refer to existing DAG projects that use the `airflow_docker_dev_setup` project:

- [COB Data Pipeline](https://github.com/tulibraries/cob_datapipeline/)
- [Funcake DAGS](https://github.com/tulibraries/funcake_dags)
- [Manifold AirflOW DAGs](https://github.com/tulibraries/manifold_airflow_dags/)

Three specifics to note:

- Add this Git repository as a submodule to the root of the DAG you are developing.

```
git submodule add git@github.com:tulibraries/airflow-docker-dev-setup
```

- Commit newly created `.gitmodules` file and `airflow-docker-dev-setup` directory. 

```
git add .gitmodules airflow-docker-dev-setup
```

- Create a file called `local.env`. add the line `DAG_DIR=my_dag_dir` with the actual name of the directory in the root of the repo containing your dag files.


## Usage

The `airflow_docker_dev_setup` submodleu uses the UNIX `make` command to control Docker containers. To run Airflow in within a containerized dev environment, execute the `make` commands with the targets shown below. 

```

$ make up

```

This spins up an Airflow stack using PostgreSQL for the metadata database; Celery, Redis & Flower for job management; CeleryExecutor, Scheduler, Web-Server and Worker Airflow services; and mounting the local `dags` directory as the Airflow stack's DAGs directory. That DAGs directory has cob_datapipeline and manifold_airflow_dags cloned into it if these subdirectories do not already exist. This will also create some known Variables and Connections, based off of `data/example-variables.json` (the task copies this into `data/variables.json` if that file doesn't exist, then loads variables into Airflow from there).

Give this up to 1 minute to start up. You can check the Airflow web-server health-check state by running:

```
$ docker-compose -p infra ps
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

#### Load Airflow Variables

```
  $ make load-vars
```

Load the airflow variables, in `variables.json`


#### Start Bash in a Given Docker Instance

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

### Start Bash as Root in a Given Docker Instance

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

### Development commands

Lint files (check for python language errors) in ./dags folder (mounted volume):

```
$ make lint
```

Run tests for airflow DAGs

```
$ make test
```

Clone DAGs into ./dags folder (mounted volume):

```
$ make clone-dags
```

Load Variables & Connections DAGs into Airflow:

```
$ make load-vars:
```
