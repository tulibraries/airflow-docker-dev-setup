ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
FROM apache/airflow:2.9.3-python3.11

# Install git
USER root
RUN apt-get update -y && \
  apt-get install -y git libssl-dev \
  libreadline-dev jq bzip2 \
  build-essential libffi-dev libyaml-dev \
  zlib1g-dev

# Install java for the system.
RUN mkdir -p /usr/share/man/man1
RUN apt-get update -y
RUN apt-get install -y default-jre

COPY docker-requirements.txt /app/requirements.txt
RUN chown airflow -R /app

#Set Airflow user and Pip install packages
USER airflow
ENV AIRFLOW_USER_HOME=/opt/airflow
RUN python3.11 -m pip install --no-cache-dir -r /app/requirements.txt

# Install rbenv and ruby for airflow user.
RUN git clone https://github.com/rbenv/rbenv.git ${AIRFLOW_USER_HOME}/.rbenv
RUN git clone https://github.com/rbenv/ruby-build.git ${AIRFLOW_USER_HOME}/.rbenv/plugins/ruby-build
ENV PATH ${AIRFLOW_USER_HOME}/.rbenv/shims:${AIRFLOW_USER_HOME}/.rbenv/bin:${AIRFLOW_USER_HOME}/.rbenv/plugins/ruby-build/bin:$PATH
ENV RBENV_SHELL=bash
ENV CONFIGURE_OPTS --disable-install-doc

RUN rbenv install 3.3.0 && rbenv global 3.3.0 && rbenv rehash

RUN eval "$(rbenv init -)" &&  gem install bundler

# start airflow worker
WORKDIR ${AIRFLOW_USER_HOME}
