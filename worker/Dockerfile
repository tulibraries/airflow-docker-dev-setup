ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
FROM apache/airflow:1.10.14

# Install git
USER root
RUN apt-get update -y && \
  apt-get install -y git libssl-dev \
  libreadline-dev jq bzip2 \
  build-essential \
  zlib1g-dev

# Install java for the system.
RUN mkdir -p /usr/share/man/man1
RUN apt-get update -y
RUN apt-get install -y default-jre

# Install rbenv and ruby for airflow user.
USER airflow
ARG AIRFLOW_USER_HOME=/opt/airflow
RUN git clone https://github.com/rbenv/rbenv.git ${AIRFLOW_USER_HOME}/.rbenv
RUN git clone https://github.com/rbenv/ruby-build.git ${AIRFLOW_USER_HOME}/.rbenv/plugins/ruby-build
ENV PATH ${AIRFLOW_USER_HOME}/.rbenv/shims:${AIRFLOW_USER_HOME}/.rbenv/bin:${AIRFLOW_USER_HOME}/.rbenv/plugins/ruby-build/bin:$PATH
ENV RBENV_SHELL=bash
ENV CONFIGURE_OPTS --disable-install-doc

RUN rbenv install 2.7.2 && rbenv global 2.7.2 && rbenv rehash

RUN eval "$(rbenv init -)" &&  gem install bundler

# start airflow worker
WORKDIR ${AIRFLOW_USER_HOME}
