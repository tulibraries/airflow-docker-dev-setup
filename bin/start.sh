#!/usr/bin/env bash

airflow db init

/entrypoint api-server
