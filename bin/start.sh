#!/usr/bin/env bash

airflow db migrate

/entrypoint api-server
