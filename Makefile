up: down build load-vars add-user
	@echo "Building airflow with mounted DAGs, loaded variables, connections."

build:
	@echo "Building airflow containers, networks, volumes"
	docker compose pull
	docker compose -p 'infra' up --build -d
	sleep 20
	@echo "airflow running on http://127.0.0.1:8010"

reload:
	@echo "Updating solr containers, networks, volumes"
	docker compose -p 'infra' restart

stop:
	@echo "Stopping airflow containers, networks, volumes"
	docker compose -p 'infra' stop

down: stop
	@echo "Killing airflow containers, networks, volumes"
	docker compose -p 'infra' rm -fv

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
	# if [ ! -f "data/variables.json" ]; then cp example-variables.json data/variables.json; fi
	# docker exec infra-webserver-1 airflow variables import /opt/airflow/data/variables.json
	if [ ! -f "data/local-dev-variables.json" ]; then cp ../variables.json data/local-dev-variables.json; fi
	docker exec infra-webserver-1 airflow variables import /opt/airflow/data/local-dev-variables.json
	docker exec infra-webserver-1 airflow connections add AIRFLOW_CONN_SLACK_WEBHOOK --conn-type http --conn-host https://hooks.slack.com/services --conn-password blah
	docker exec infra-webserver-1 airflow connections add AIRFLOW_CONN_SOLR_LEADER --conn-uri http://solr1:8983
	docker exec infra-webserver-1 airflow connections add SOLRCLOUD --conn-uri http://solr1:8983
	docker exec infra-webserver-1 airflow connections add library_website --conn-uri https://library.temple.edu
	docker exec infra-webserver-1 airflow connections add SOLRCLOUD-WRITER --conn-uri http://solr1:8983
	docker exec infra-webserver-1 airflow connections add AIRFLOW_CONN_MANIFOLD_INSTANCE --conn-uri http://127.0.0.1:8010
	docker exec infra-webserver-1 airflow connections add AIRFLOW_S3 --conn-type aws --conn-login "blah" --conn-password "blerg"
	docker exec infra-webserver-1 airflow connections add AIRFLOW_CONN_MANIFOLD_SSH_INSTANCE --conn-type ssh --conn-host 192.168.10.22 --conn-login vagrant --conn-password vagrant --conn-port 22 --conn-extra '{"no_host_key_check": "true"}'
	docker exec infra-webserver-1 airflow connections add manifold-db --conn-type ssh --conn-host host.docker.internal --conn-login vagrant --conn-password vagrant --conn-port 2223 --conn-extra '{"key_file": "/opt/airflow/.ssh/private_key", "no_host_key_check": "true"}'
	if [ "$(TUPSFTP_PASSWORD)" != "" ]; then \
			docker exec infra-webserver-1 airflow connections add AIRFLOW_CONN_TUPSFTP --conn-type ssh --conn-host sftp.tul-infra.page --conn-login $(TUP_SFTP_ACCOUNT_NAME) --conn-password '$(TUPSFTP_PASSWORD)' --conn-port 9229 --conn-extra '{"no_host_key_check": "true"}'; \
			docker exec infra-webserver-1 airflow connections add $(TUP_SFTP_ACCOUNT_NAME) --conn-type ssh --conn-host sftp.tul-infra.page --conn-login tupsftp --conn-password '$(TUPSFTP_PASSWORD)' --conn-port 9229  --conn-extra '{"no_host_key_check": "true"}'; \
			docker exec infra-webserver-1 airflow connections add AIRFLOW_CONN_TUPRESS --conn-type ssh --conn-host 173.255.195.105 --conn-login $(TUP_ACCOUNT_NAME) --conn-port 9229 --conn-extra '{"key_file": "$(TUP_SSH_KEY_PATH)" "no_host_key_check": true}'; \
			docker exec infra-webserver-1 airflow connections add tupress --conn-type ssh --conn-host 173.255.195.105 --conn-login $(TUP_ACCOUNT_NAME) --conn-port 9229 --conn-extra '{"key_file": "$(TUP_SSH_KEY_PATH)", "no_host_key_check": true}'; \
			docker compose -p infra exec worker mkdir -m 700 .ssh; \
			docker cp $(WORKER_SSH_KEY_PATH) infra-worker-1:/opt/airflow/.ssh/conan_the_deployer; \
		fi

add-user:
	docker exec infra-webserver-1 airflow users create -u test-user -f first -l last -e test@test.com -p password -r Admin

setup-manifold-ssh:
	@echo "Setting up airflow to ssh to a local manifold Vagrant instance on port 2222"
	docker exec infra-worker-1 mkdir -p /opt/airflow/.ssh/
	docker exec infra-worker-1 chmod 700 /opt/airflow/.ssh
	docker cp $(MANIFOLD_DIR)/.vagrant/machines/manifold-vagrant-01/virtualbox/private_key \
		infra-worker-1:/opt/airflow/.ssh/
	docker exec -u root infra-worker-1 chown airflow:airflow \
		/opt/airflow/.ssh/private_key

tty-worker:
	docker exec -it infra-worker-1 /bin/bash

tty-webserver:
	docker exec -it infra-webserver-1 /bin/bash

tty-scheduler:
	docker exec -it infra-scheduler-1 /bin/bash

tty-root-worker:
	docker exec -u root -it infra-worker-1 /bin/bash

tty-root-webserver:
	docker exec -u root -it infra-webserver-1 /bin/bash

tty-root-scheduler:
	docker exec -u root -it infra-scheduler-1 /bin/bash
