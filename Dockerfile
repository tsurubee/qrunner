FROM ruby:2.6

ENV RUBYOPT -EUTF-8

RUN apt-get update && apt-get -y install mysql-client

RUN mkdir -p /usr/local/qrunner
ADD lib/qrunner.rb /usr/local/qrunner

RUN gem install 'mysql2' \
    'toml-rb' \
    'net-ssh-gateway'
