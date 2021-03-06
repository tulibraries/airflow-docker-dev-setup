up: down build pip-install load-vars
	@echo "Building airflow with mounted DAGs, loaded variables, connections."

build:
	@echo "Building airflow containers, networks, volumes"
	docker-compose pull
	docker-compose -p 'infra' up --build -d
	sleep 20
	@echo "airflow running on http://127.0.0.1:8010"

reload:
	@echo "Updating solr containers, networks, volumes"
	docker-compose -p 'infra' restart

stop:
	@echo "Stopping airflow containers, networks, volumes"
	docker-compose -p 'infra' stop

down: stop
	@echo "Killing airflow containers, networks, volumes"
	docker-compose -p 'infra' rm -fv

lint:
	@echo "Linting files in ./dags folder (mounted volume)"
	if [ ! -d "dags/cob_datapipeline" ]; then pipenv run pylint cob_datapipeline -E; fi
	if [ ! -d "dags/manifold_airflow_dags" ]; then pipenv run pylint manifold_airflow_dags -E; fi
	if [ ! -d "dags/funcake_dags" ]; then pipenv run pylint funcake_dags -E; fi
	.circleci/pylint

test:
	pipenv run pytest

clone-dags:
	@echo "Cloning DAGs into ./dags folder (mounted volume)"
	if [ ! -d "dags/cob_datapipeline" ]; then git clone https://github.com/tulibraries/cob_datapipeline.git dags/cob_datapipeline; fi
	if [ ! -d "dags/manifold_airflow_dags" ]; then git clone https://github.com/tulibraries/manifold_airflow_dags.git dags/manifold_airflow_dags; fi
	if [ ! -d "dags/funcake_dags" ]; then git clone https://github.com/tulibraries/funcake_dags.git dags/funcake_dags; fi

load-vars:
	@echo "Loading Variables & Connections DAGs into Airflow"
	if [ ! -f "data/variables.json" ]; then cp example-variables.json data/variables.json; fi
	docker exec infra_webserver_1 airflow variables -i /opt/airflow/data/variables.json
	if [ ! -f "data/local-variables.json" ]; then cp ../variables.json data/local-variables.json; fi
	docker exec infra_webserver_1 airflow variables -i /opt/airflow/data/local-variables.json
	docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_CONN_SLACK_WEBHOOK --conn_type HTTP --conn_host https://hooks.slack.com/services --conn_password blah
	docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_CONN_SOLR_LEADER --conn_uri http://solr1:8983
	docker exec infra_webserver_1 airflow connections -a --conn_id SOLRCLOUD --conn_uri http://solr1:8983
	docker exec infra_webserver_1 airflow connections -a --conn_id SOLRCLOUD-WRITER --conn_uri http://solr1:8983
	docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_CONN_MANIFOLD_INSTANCE --conn_uri http://127.0.0.1:8010
	docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_S3 --conn_type AWS --conn_login "blah" --conn_password "blerg"
	docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_CONN_MANIFOLD_SSH_INSTANCE --conn_type ssh --conn_host 192.168.10.22 --conn_login vagrant --conn_password vagrant --conn_port 22 --conn_extra '{"no_host_key_check": "true"}'
	docker exec infra_webserver_1 airflow connections -a --conn_id manifold-db --conn_type ssh --conn_host host.docker.internal --conn_login vagrant --conn_password vagrant --conn_port 2223 --conn_extra '{"key_file": "/opt/airflow/.ssh/private_key", "no_host_key_check": "true"}'
	if [ "$(TUPSFTP_PASSWORD)" != "" ]; then \
			docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_CONN_TUPSFTP --conn_type ssh --conn_host sftp.tul-infra.page --conn_login $(TUP_SFTP_ACCOUNT_NAME) --conn_password '$(TUPSFTP_PASSWORD)' --conn_port 9229 --conn_extra '{"no_host_key_check": "true"}'; \
			docker exec infra_webserver_1 airflow connections -a --conn_id $(TUP_SFTP_ACCOUNT_NAME) --conn_type ssh --conn_host sftp.tul-infra.page --conn_login tupsftp --conn_password '$(TUPSFTP_PASSWORD)' --conn_port 9229  --conn_extra '{"no_host_key_check": "true"}'; \
			docker exec infra_webserver_1 airflow connections -a --conn_id AIRFLOW_CONN_TUPRESS --conn_type ssh --conn_host 173.255.195.105 --conn_login $(TUP_ACCOUNT_NAME) --conn_port 9229 --conn_extra '{"key_file": "$(TUP_SSH_KEY_PATH)" "no_host_key_check": true}'; \
			docker exec infra_webserver_1 airflow connections -a --conn_id tupress --conn_type ssh --conn_host 173.255.195.105 --conn_login $(TUP_ACCOUNT_NAME) --conn_port 9229 --conn_extra '{"key_file": "$(TUP_SSH_KEY_PATH)", "no_host_key_check": true}'; \
			docker-compose -p infra exec worker mkdir -m 700 .ssh; \
			docker cp $(WORKER_SSH_KEY_PATH) infra_worker_1:/opt/airflow/.ssh/conan_the_deployer; \
		fi


setup-manifold-ssh:
	@echo "Setting up airflow to ssh to a local manifold Vagrant instance on port 2222"
	docker exec infra_worker_1 mkdir -p /opt/airflow/.ssh/
	docker exec infra_worker_1 chmod 700 /opt/airflow/.ssh
	docker cp $(MANIFOLD_DIR)/.vagrant/machines/manifold-vagrant-01/virtualbox/private_key \
		infra_worker_1:/opt/airflow/.ssh/
	docker exec -u root infra_worker_1 chown airflow:airflow \
		/opt/airflow/.ssh/private_key

pip-install:
	docker exec infra_worker_1 pip install  --user -r /requirements.txt --constraint=https://raw.githubusercontent.com/apache/airflow/constraints-1-10/constraints-3.6.txt
	docker exec infra_scheduler_1 pip install  --user -r /requirements.txt --constraint=https://raw.githubusercontent.com/apache/airflow/constraints-1-10/constraints-3.6.txt
	docker exec infra_webserver_1 pip install  --user -r /requirements.txt --constraint=https://raw.githubusercontent.com/apache/airflow/constraints-1-10/constraints-3.6.txt

tty-worker:
	docker exec -it infra_worker_1 /bin/bash

tty-webserver:
	docker exec -it infra_webserver_1 /bin/bash

tty-scheduler:
	docker exec -it infra_scheduler_1 /bin/bash

tty-root-worker:
	docker exec -u root -it infra_worker_1 /bin/bash

tty-root-webserver:
	docker exec -u root -it infra_webserver_1 /bin/bash

tty-root-scheduler:
	docker exec -u root -it infra_scheduler_1 /bin/bash
