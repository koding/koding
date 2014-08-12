#!/bin/bash

cp scripts/wercker/social-api.conf /etc/init/social-api.conf
touch /etc/init.d/social-api
initctl emit social-api POSTGRES_HOST=$WERCKER_POSTGRESQL_HOST \
                        POSTGRES_PORT=$WERCKER_POSTGRESQL_PORT \
                        POSTGRES_USERNAME=$WERCKER_POSTGRESQL_USERNAME \
                        POSTGRES_PASSWORD=$WERCKER_POSTGRESQL_PASSWORD \
                        POSTGRES_DBNAME=$WERCKER_POSTGRESQL_DATABASE \
                        RABBITMQ_HOST=$WERCKER_RABBITMQ_HOST \
                        RABBITMQ_PORT=$WERCKER_RABBITMQ_PORT \
                        RABBITMQ_USERNAME=$WERCKER_RABBITMQ_USERNAME \
                        RABBITMQ_PASSWORD=$WERCKER_RABBITMQ_PASSWORD \
                        REDIS_URL=$WERCKER_REDIS_HOST:$WERCKER_REDIS_PORT \
                        MONGO_URL=$WERCKER_MONGODB_URL \
                        WERCKER_SOURCE_DIR=$WERCKER_SOURCE_DIR


cp scripts/wercker/social-populartopic.conf /etc/init/social-populartopic.conf
touch /etc/init.d/social-populartopic
initctl emit social-populartopic POSTGRES_HOST=$WERCKER_POSTGRESQL_HOST \
                        POSTGRES_PORT=$WERCKER_POSTGRESQL_PORT \
                        POSTGRES_USERNAME=$WERCKER_POSTGRESQL_USERNAME \
                        POSTGRES_PASSWORD=$WERCKER_POSTGRESQL_PASSWORD \
                        POSTGRES_DBNAME=$WERCKER_POSTGRESQL_DATABASE \
                        RABBITMQ_HOST=$WERCKER_RABBITMQ_HOST \
                        RABBITMQ_PORT=$WERCKER_RABBITMQ_PORT \
                        RABBITMQ_USERNAME=$WERCKER_RABBITMQ_USERNAME \
                        RABBITMQ_PASSWORD=$WERCKER_RABBITMQ_PASSWORD \
                        REDIS_URL=$WERCKER_REDIS_HOST:$WERCKER_REDIS_PORT \
                        MONGO_URL=$WERCKER_MONGODB_URL \
                        WERCKER_SOURCE_DIR=$WERCKER_SOURCE_DIR
