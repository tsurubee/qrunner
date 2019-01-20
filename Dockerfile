FROM ruby:2.6

RUN apt-get update && apt-get -y install mysql-client

RUN mkdir -p /usr/local/qrunner
ADD Gemfile /usr/local/qrunner
ADD lib/qrunner.rb /usr/local/qrunner

WORKDIR /usr/local/qrunner
RUN bundle install --path /tmp/bundle
