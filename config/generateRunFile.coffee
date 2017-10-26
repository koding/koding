traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'
{ isAllowed }         = require '../deployment/grouptoenvmapping'

generateDev = (KONFIG, options) ->

  options.requirementCommands ?= []

  run = """
    #!/bin/bash

    # ------ THIS FILE IS AUTO-GENERATED ON EACH BUILD ----- #

    export KONFIG_PROJECTROOT=$(cd $(dirname $0); pwd)

    ENV_SHELL_FILE=${ENV_SHELL_FILE:-$(dirname $0)/.env.sh}
    if [ -f "$ENV_SHELL_FILE" ]; then
      source $ENV_SHELL_FILE
    else
      echo "error: shell environment file does not exist"
      exit 1
    fi

    function is_ready () {
      check_connectivity mongo
      check_connectivity postgres
      check_connectivity redis
      check_connectivity rabbitmq
      # check_connectivity countly
    }

    mkdir $KONFIG_PROJECTROOT/.logs &>/dev/null

    SERVICES="mongo redis postgres rabbitmq countly"

    #{options.requirementCommands?.join "\n"}

    trap ctrl_c INT

    function ctrl_c () {
      supervisorctl shutdown
      exit 1;
    }

    function checkrunfile () {

      if [ "$KONFIG_PROJECTROOT/run" -ot "$KONFIG_PROJECTROOT/config/main.$KONFIG_CONFIGNAME.coffee" ]; then
          echo your run file is older than your config file. doing ./configure.
          sleep 1
          ./configure

          echo -e "\n\nPlease do ./run again\n"
          exit 1;
      fi

      if [ "$KONFIG_PROJECTROOT/run" -ot "$KONFIG_PROJECTROOT/configure" ]; then
          echo your run file is older than your configure file. doing ./configure.
          sleep 1
          ./configure

          echo -e "\n\nPlease do ./run again\n"
          exit 1;
      fi
    }

    function apply_custom_pg_migrations () {
      # we can remove these after https://github.com/mattes/migrate/issues/13
      export PGPASSWORD=$KONFIG_POSTGRES_PASSWORD
      PSQL_COMMAND="psql -tA -h $KONFIG_POSTGRES_HOST $KONFIG_POSTGRES_DBNAME -U $KONFIG_POSTGRES_USERNAME"
      $PSQL_COMMAND -c "ALTER TYPE \"api\".\"channel_type_constant_enum\" ADD VALUE IF NOT EXISTS 'collaboration';"
      $PSQL_COMMAND -c "ALTER TYPE \"api\".\"channel_participant_status_constant_enum\" ADD VALUE IF NOT EXISTS 'blocked';"
      $PSQL_COMMAND -c "ALTER TYPE \"api\".\"channel_type_constant_enum\" ADD VALUE IF NOT EXISTS 'linkedtopic';"
      $PSQL_COMMAND -c "ALTER TYPE \"api\".\"channel_type_constant_enum\" ADD VALUE IF NOT EXISTS 'bot';"
      $PSQL_COMMAND -c "ALTER TYPE \"api\".\"channel_message_type_constant_enum\" ADD VALUE IF NOT EXISTS 'bot';"
      $PSQL_COMMAND -c "ALTER TYPE \"api\".\"channel_message_type_constant_enum\" ADD VALUE IF NOT EXISTS 'system';"
      $PSQL_COMMAND -c "ALTER TYPE \"payment\".\"plan_title_enum\" ADD VALUE IF NOT EXISTS 'bootstrap';"
      $PSQL_COMMAND -c "ALTER TYPE \"payment\".\"plan_title_enum\" ADD VALUE IF NOT EXISTS 'startup';"
      $PSQL_COMMAND -c "ALTER TYPE \"payment\".\"plan_title_enum\" ADD VALUE IF NOT EXISTS 'enterprise';"
      $PSQL_COMMAND -c "ALTER TYPE \"payment\".\"plan_title_enum\" ADD VALUE IF NOT EXISTS 'team_base';"
      $PSQL_COMMAND -c "ALTER TYPE \"payment\".\"plan_title_enum\" ADD VALUE IF NOT EXISTS 'team_free';"
    }

    function run () {

      # Update node modules
      if ! scripts/check-node_modules.sh; then
        npm install --silent
      fi

      # Check everything else
      check

      # Run Go builder
      $KONFIG_PROJECTROOT/go/build.sh

      # Do PG Migration if necessary
      migrations up

      supervisord && sleep 1

      # Show the all logs of workers
      tail -fq ./.logs/*.log

    }

    function docker_compose() {
      if ! which docker-compose; then
        echo 'error: docker-compose is not found'
        echo '$ pip install docker-compose'
        exit 1
      fi

      local ENTRYPOINT="/opt/koding/scripts/bootstrap-container $@"

      docker-compose run --entrypoint $ENTRYPOINT backend
    }

    function printHelp (){

      echo "Usage: "
      echo ""
      echo "  run                       : to start koding"
      echo "  run docker-compose        : to start koding in docker-compose environment"
      echo "  run exec                  : to exec arbitrary commands"
      echo "  run install               : to compile/install client and "
      echo "  run buildclient           : to see of specified worker logs only"
      echo "  run logs                  : to see all workers logs"
      echo "  run log [worker]          : to see of specified worker logs only"
      echo "  run buildservices         : to initialize and start services"
      echo "  run services              : to stop and restart services"
      echo "  run printconfig           : to print koding config environment variables (output in json via --json flag)"
      echo "  run migrate [command]     : to apply/revert database changes (command: [create|up|down|version|reset|redo|to|goto])"
      echo "  run mongomigrate [command]: to apply/revert mongo database changes (command: [create|up|down])"
      echo "  run migrations [command]  : to apply/revert mongo and postgres database changes (command: [create|up|down])"
      echo "  run nodeservertests       : to run tests for node.js web server"
      echo "  run socialworkertests     : to run tests for social worker"
      echo "  run nodetestfiles         : to run a single test or all test files in a directory"
      echo "  run switchclient [rev]    : to switch client version to provided revision (revision: [default|rev])"
      echo "  run help                  : to show this list"
      echo ""

    }

    function migrate () {
      apply_custom_pg_migrations

      params=(create up down version reset redo to goto)
      param=$1

      case "${params[@]}" in  *"$param"*)
        ;;
      *)
        echo "Error: Command not found: $param"
        echo "Usage: run migrate COMMAND [arg]"
        echo ""
        echo "Commands:  "
        echo "  create [filename] : create new migration file in path"
        echo "  up                : apply all available migrations"
        echo "  down              : roll back all migrations"
        echo "  redo              : roll back the most recently applied migration, then run it again"
        echo "  reset             : run down and then up command"
        echo "  version           : show the current migration version"
        echo "  to   [n]          : (+n) apply the next n / (-n) roll back the previous n migrations"
        echo "  goto [n]          : go to specific migration"

        echo ""
        exit 1
      ;;
      esac

      if [ "$param" == "to" ]; then
        param="migrate"
      elif [ "$param" == "create" ] && [ -z "$2" ]; then
        echo "Please choose a migration file name. (ex. add_created_at_column_account)"
        echo "Usage: run migrate create [filename]"
        echo ""
        exit 1
      fi

      local pgssl=$(psql --quiet --tuples-only --command "show ssl;" $KONFIG_POSTGRES_URL | tr -d '[:space:]')
      if [[ "$pgssl" == "off" ]]; then
        export PGSSLMODE="disable"
      fi

      $GOBIN/migrate -url "postgres://$KONFIG_POSTGRES_HOST:$KONFIG_POSTGRES_PORT/$KONFIG_POSTGRES_DBNAME?user=social_superuser&password=social_superuser" -path "$KONFIG_PROJECTROOT/go/src/socialapi/db/sql/migrations" $param $2

      if [ "$param" == "create" ]; then
        echo "Please edit created script files and add them to your repository."
      fi
    }

    function mongomigrate () {
      params=(create up down)
      param=$1
      case "${params[@]}" in  *"$param"*)
        ;;
      *)
        echo "Error: Command not found: $param"
        echo "Usage: run migrate COMMAND [arg]"
        echo ""
        echo "Commands:  "
        echo "  create [filename] : create new migration file under ./workers/migrations (ids will increase by 5)"
        echo "  up                : apply all available migrations"
        echo "  down [id]         : roll back to id (if not given roll back all migrations)"

        echo ""
        exit 1
      ;;
      esac

      if [ "$param" == "create" ] && [ -z "$2" ]; then
        echo "Please choose a migration file name. (ex. add_super_user)"
        echo "Usage: ./run mongomigrate create [filename]"
        echo ""
        exit 1
      fi

      coffee deployment/mongomigrationconfig.coffee

      node $KONFIG_PROJECTROOT/node_modules/mongodb-migrate -runmm --config ../deployment/generated_files/mongomigration.json --dbPropName conn -c $KONFIG_PROJECTROOT/workers $1 $2

      if [ "$param" == "create" ]; then
        echo "Please edit created script files and add them to your repository."
      fi
    }


    function migrations () {
      mongomigrate $1 $2
      migrate $1 $2
    }

    function check (){

      check_api_consistency
      check_service_dependencies

      mongo $KONFIG_MONGO --eval "db.stats()" > /dev/null  # do a simple harmless command of some sort

      RESULT=$?   # returns 0 if mongo eval succeeds

      if [ $RESULT -ne 0 ]; then
          echo ""
          echo "Can't talk to mongodb at $KONFIG_MONGO, is it not running? exiting."
          exit 1
      fi

      EXISTS=$(PGPASSWORD=$KONFIG_POSTGRES_PASSWORD psql -tA -h $KONFIG_POSTGRES_HOST social -U $KONFIG_POSTGRES_USERNAME -c "Select 1 from pg_tables where tablename = 'key' AND schemaname = 'kite';")
      if [[ $EXISTS != '1' ]]; then
        echo ""
        echo "You don't have the new Kontrol Postgres. Please call ./run buildservices."
        exit 1
      fi

    }

    function check_psql () {
      command -v psql          >/dev/null 2>&1 || { echo >&2 "I require psql but it's not installed. (brew install postgresql)  Aborting."; exit 1; }
    }

    function check_service_dependencies () {
      echo "checking required services: nginx, docker, mongo, graphicsmagick..."
      command -v curl          >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed.  Aborting."; exit 1; }
      command -v go            >/dev/null 2>&1 || { echo >&2 "I require go but it's not installed.  Aborting."; exit 1; }
      command -v docker        >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }
      command -v nginx         >/dev/null 2>&1 || { echo >&2 "I require nginx but it's not installed. (brew install nginx maybe?)  Aborting."; exit 1; }
      command -v pg_isready    >/dev/null 2>&1 || { echo >&2 "I require pg_isready but it's not installed. (brew install postgresql maybe?)  Aborting."; exit 1; }
      command -v node          >/dev/null 2>&1 || { echo >&2 "I require node but it's not installed.  Aborting."; exit 1; }
      command -v npm           >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }
      command -v coffee        >/dev/null 2>&1 || { echo >&2 "I require coffee-script but it's not installed. (npm i coffee-script -g)  Aborting."; exit 1; }
      check_psql

      if [[ `uname` == 'Darwin' ]]; then
        brew info graphicsmagick >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }
      elif [[ `uname` == 'Linux' ]]; then
        command -v gm >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }
      fi

      set -o errexit

      scripts/check-node-version.sh
      scripts/check-npm-version.sh
      scripts/check-gulp-version.sh
      scripts/check-go-version.sh
      scripts/check-supervisor.sh
      scripts/check-mongo-version.sh

      set +o errexit
    }

    function check_connectivity_mongo() {
      local MONGO_OK=$(mongo $KONFIG_MONGO \
                       --quiet \
                       --eval "db.serverStatus().ok == true")

      if [[ $? != 0 || "$MONGO_OK" != true ]]; then
        echo "error: mongodb service check failed on $KONFIG_MONGO"
        return 1
      fi

      return 0
    }

    function check_connectivity_rabbitmq() {
      local USER=$KONFIG_MQ_LOGIN:$KONFIG_MQ_PASSWORD
      local HOST=$KONFIG_MQ_HOST:$KONFIG_MQ_APIPORT
      local RESPONSE_CODE=$(curl --silent --output /dev/null --write-out '%{http_code}' --user $USER http://$HOST/api/overview)

      if [[ $? != 0 || $RESPONSE_CODE != 200 ]]; then
        echo "error: rabbitmq service check failed on $KONFIG_MQ_HOST:$KONFIG_MQ_APIPORT"
        return 1
      fi

      return 0
    }

    function check_connectivity_countly() {
      local HOST=$KONFIG_COUNTLY_HOST/
      local RESPONSE_CODE=$(curl --silent --output /dev/null --write-out '%{http_code}' $HOST)

      if [[ $? != 0 || $RESPONSE_CODE != 302 ]]; then
        echo "error: countly service check failed on $HOST"
        return 1
      fi

      return 0
    }


    function check_connectivity_postgres() {
      pg_isready --host $KONFIG_POSTGRES_HOST \
                 --port $KONFIG_POSTGRES_PORT \
                 --username $KONFIG_POSTGRES_USERNAME \
                 --dbname $KONFIG_POSTGRES_DBNAME \
                 --quiet

      if [ $? != 0 ]; then
        echo "error: postgres service check failed on $KONFIG_POSTGRES_HOST:$KONFIG_POSTGRES_PORT"
        return 1
      fi

      return 0
    }


    function check_connectivity_redis() {
      local REDIS_PONG=$(redis-cli -h $KONFIG_REDIS_HOST \
                -p $KONFIG_REDIS_PORT \
                ping)

      if [[ $? != 0 || "$REDIS_PONG" != PONG ]]; then
        echo "error: redis service check failed on $KONFIG_REDIS_HOST:$KONFIG_REDIS_PORT"
        return 1
      fi

      return 0
    }

    function check_connectivity() {
      retries=600
      until eval "check_connectivity_$@"; do
        sleep 1
        let retries--
        if [ $retries == 0 ]; then
          echo "time out while waiting for $@ is ready"
          exit 1
        fi
        echo "$@ is not reachable yet, trying again..."
      done
      echo "$@ is up and running..."

    }

    function check_api_consistency() {
      scripts/api-generator.coffee --check
    }

    function runMongoDocker () {
        docker run -d -p $KONFIG_SERVICEHOST:27017:27017 --name=mongo mongo:3.2.8 --nojournal --noprealloc --smallfiles
        check_connectivity mongo
    }

    function runPostgresqlDocker () {
        docker run -d -p $KONFIG_SERVICEHOST:5432:5432 --name=postgres koding/postgres
        check_connectivity postgres
    }

    function runRabbitMQDocker () {
        docker run -d -p $KONFIG_SERVICEHOST:5672:5672 -p 15672:15672 --name=rabbitmq rabbitmq:3-management
        check_connectivity rabbitmq
    }

    function runCountlyDocker () {
        docker run -d -p $KONFIG_COUNTLY_APIPORT:80 --env 'COUNTLY_PATH=/countly' --env 'COUNTLY_WITH_DEFAULT_DATA=1' --name=countly koding/countly-server:latest
        check_connectivity countly
        dexec countly /opt/countly/bin/backup/run.sh
    }

    function runRedisDocker () {
        docker run -d -p $KONFIG_SERVICEHOST:6379:6379 --name=redis redis
    }

    # dexec executes a script in a given docker by its name
    function dexec () {
	    local id=`docker ps -all --quiet --filter name=$1`
	    docker exec -i -t $id bash -l -c $2
    }

    function k8s () {
      params=(start stop)
      param=$1
      case "${params[@]}" in  *"$param"*)
        ;;
      *)
        echo "Error: Command not found: $param"
        echo "Usage: ./run k8s COMMAND"
        echo ""
        echo "Commands:  "
        echo "  start : install the services in Kubernetes pods"
        echo "  stop  : stop the currently running Kubernetes cluster"

        echo ""
        exit 1
      ;;
      esac

      if [ "$param" == "start" ]; then
        k8s_start

      else
        minikube stop
      fi
    }

    function k8s_start () {
      command -v docker           >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }
      command -v minikube         >/dev/null 2>&1 || { echo >&2 "I require a Kubernetes cluster. To install minikube: \
              (curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.20.0/minikube-$(uname | awk '{print tolower($0)}')-amd64 && chmod +x minikube && mv minikube /usr/local/bin/)"; exit 1;}
      command -v kubectl          >/dev/null 2>&1 || { echo >&2 "I require kubectl. To install kubectl: \
              (curl -L -O https://storage.googleapis.com/kubernetes-release/release/v1.6.4/bin/$(uname | awk '{print tolower($0)}')/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/)"; exit 1;}

      export CHANGE_MINIKUBE_NONE_USER=true
      sudo -E minikube start --vm-driver=none

      sleep 90

      export NAMESPACE_DIR="${KONFIG_PROJECTROOT}/deployment/kubernetes/namespace.yaml"
      export FRONTEND_DIR="${KONFIG_PROJECTROOT}/deployment/kubernetes/frontend-pod/client-containers.yaml"
      export BACKEND_DIR="${KONFIG_PROJECTROOT}/deployment/kubernetes/backend-pod/containers.yaml"
      export BUILD_DIR="${KONFIG_PROJECTROOT}/deployment/kubernetes/build-pod.yaml"

      cp $BACKEND_DIR ${KONFIG_PROJECTROOT}/deployment/generated_files/
      cp $BUILD_DIR ${KONFIG_PROJECTROOT}/deployment/generated_files/
      cp $FRONTEND_DIR ${KONFIG_PROJECTROOT}/deployment/generated_files/

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource $NAMESPACE_DIR

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource ${KONFIG_PROJECTROOT}/deployment/kubernetes/external-services/mongo
      export MONGO_POD_NAME=$(kubectl get pods --namespace koding -l "app=mongo-ext-service" -o jsonpath="{.items[0].metadata.name}")
      $KONFIG_PROJECTROOT/scripts/k8s-utilities.sh check_pod_state $MONGO_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource ${KONFIG_PROJECTROOT}/deployment/kubernetes/external-services/countly
      export COUNTLY_POD_NAME=$(kubectl get pods --namespace koding -l "app=countly-ext-service" -o jsonpath="{.items[0].metadata.name}")
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $COUNTLY_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource ${KONFIG_PROJECTROOT}/deployment/kubernetes/external-services/postgres
      export POSTGRES_POD_NAME=$(kubectl get pods --namespace koding -l "app=postgres-ext-service" -o jsonpath="{.items[0].metadata.name}")
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $POSTGRES_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource ${KONFIG_PROJECTROOT}/deployment/kubernetes/external-services/redis
      export REDIS_POD_NAME=$(kubectl get pods --namespace koding -l "app=redis-ext-service" -o jsonpath="{.items[0].metadata.name}")
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $REDIS_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource ${KONFIG_PROJECTROOT}/deployment/kubernetes/external-services/rabbitmq
      export RABBITMQ_POD_NAME=$(kubectl get pods --namespace koding -l "app=rabbitmq-ext-service" -o jsonpath="{.items[0].metadata.name}")
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $RABBITMQ_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource $FRONTEND_DIR
      export FRONTEND_POD_NAME="frontend"
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $FRONTEND_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource $BUILD_DIR
      export BUILD_POD_NAME="workers-build"
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $BUILD_POD_NAME Pending

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_rmq_test_user

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $BUILD_POD_NAME Running Succeeded

      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh create_k8s_resource $BACKEND_DIR
      export BACKEND_POD_NAME="backend"
      ${KONFIG_PROJECTROOT}/scripts/k8s-utilities.sh check_pod_state $BACKEND_POD_NAME Pending

      echo "all services are ready..."
    }

    function switch_client_version () {
      if [ "$1" == "default" ]; then
        rm $KONFIG_PROJECTROOT/CLIENTVERSION
      else
        echo $1 > $KONFIG_PROJECTROOT/CLIENTVERSION
      fi
      pkill -SIGPIPE koding-webserver
    }

    function build_services () {

      # Build postgres
      pushd $KONFIG_PROJECTROOT/go/src/socialapi/db/sql
      mkdir -p kontrol
      sed -i -e "s/USER kontrolapplication/USER $KONFIG_KONTROL_POSTGRES_USERNAME/" kontrol/001-schema.sql
      sed -i -e "s/PASSWORD 'kontrolapplication'/PASSWORD '$KONFIG_KONTROL_POSTGRES_PASSWORD'/" kontrol/001-schema.sql
      sed -i -e "s/GRANT kontrol TO kontrolapplication/GRANT kontrol TO $KONFIG_KONTROL_POSTGRES_USERNAME/" kontrol/001-schema.sql
      docker build -t koding/postgres .
      git checkout kontrol/001-schema.sql
      popd

      restoredefaultmongodump
      restoreredis
      restorerabbitmq
      if [ ! -z $KONFIG_COUNTLYPATH ]; then
        $KONFIG_PROJECTROOT/deployment/countly/preparecountly.sh
      else
        restorecountly
      fi
      restoredefaultpostgresdump
    }

    function services () {

      EXISTS=$(docker inspect --format="{{ .State.Running }}" $SERVICES 2> /dev/null)
      if [ $? -eq 1 ]; then
        echo ""
        echo "Some of containers are missing, please do ./run buildservices"
        exit 1
      fi

      echo "Stopping services: $SERVICES"
      docker stop $SERVICES

      echo "Starting services: $SERVICES"
      docker start $SERVICES
    }

    function removeDockerByName () {
      docker stop $1
      docker ps -all --quiet --filter name=$1 | xargs docker rm -f && echo deleted $1 image
    }

    function restoredefaultmongodump () {
      removeDockerByName mongo
      runMongoDocker

      mongomigrate up
    }

    function restoredefaultpostgresdump () {
      removeDockerByName postgres
      runPostgresqlDocker

      migrate up

      # sync users between postgres and mongo
      go run $KONFIG_PROJECTROOT/go/src/socialapi/workers/cmd/migrator/main.go -c $KONFIG_SOCIALAPI_CONFIGFILEPATH
    }

    function restoreredis () {
      removeDockerByName redis
      runRedisDocker
    }

    function restorerabbitmq () {
      removeDockerByName rabbitmq
      runRabbitMQDocker
    }

    function restorecountly () {
      removeDockerByName countly
      runCountlyDocker
    }

    function health_check () {
      declare interval=${1:-10}
      declare timeout=${2:-60}
      declare duration=0

      declare response_code=$(curl --silent --output /dev/null \
        --write-out "%{http_code}\\n" \
        $KONFIG_PUBLICHOSTNAME/-/healthCheck)

      echo -n 'health-check: '

      until [[ $response_code -eq 200 ]]; do
        if [ $duration -eq $timeout ]; then
          echo ' timed out!'
          exit 255
        fi

        echo -n '.'

        sleep $interval
        duration=$((duration + interval))

        response_code=$(curl --silent --output /dev/null \
          --write-out "%{http_code}\\n" \
          $KONFIG_PUBLICHOSTNAME/-/healthCheck)
      done

      echo ' succeeded!'
    }

    if [ "$#" == "0" ]; then
      checkrunfile
      run $1

    elif [ "$1" == "is_ready" ]; then
      is_ready

    elif [ "$1" == "docker-compose" ]; then
      shift
      docker_compose

    elif [ "$1" == "exec" ]; then
      shift
      exec "$@"

    elif [ "$1" == "install" ]; then
      check_service_dependencies

      pushd $KONFIG_PROJECTROOT
      git submodule update --init

      npm install --unsafe-perm

      echo '#---> BUILDING CLIENT <---#'
      make -C $KONFIG_PROJECTROOT/client unit-tests

      echo '#---> BUILDING GO WORKERS <---#'
      $KONFIG_PROJECTROOT/go/build.sh

      echo '#---> BUILDING SOCIALAPI <---#'
      pushd $KONFIG_PROJECTROOT/go/src/socialapi
      make configure
      # make install

      echo '#---> AUTHORIZING THIS COMPUTER WITH MATCHING KITE.KEY <---#'
      KITE_KEY=$KONFIG_KITEHOME/kite.key
      mkdir $HOME/.kite &>/dev/null
      echo copying $KITE_KEY to $HOME/.kite/kite.key
      cp -f $KITE_KEY $HOME/.kite/kite.key

      echo
      echo
      echo 'ALL DONE. Enjoy! :)'
      echo
      echo

    elif [ "$1" == "printconfig" ]; then

      shift
      echo ${!1}

    elif [[ "$1" == "log" || "$1" == "logs" ]]; then

      trap - INT
      trap

      if [ "$2" == "" ]; then
        tail -fq ./.logs/*.log
      else
        tail -fq ./.logs/$2.log
      fi

    elif [ "$1" == "cleanup" ]; then

      ./cleanup $@

    elif [ "$1" == "buildclient" ]; then

      make -C $KONFIG_PROJECTROOT/client dist

    elif [ "$1" == "services" ]; then
      check_service_dependencies
      services

    elif [ "$1" == "buildservices" ]; then
      check_service_dependencies

      if [ "$2" != "force" ]; then
        read -p "This will destroy existing images, do you want to continue? (y/N)" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          exit 1
        fi
      fi

      build_services

    elif [ "$1" == "help" ]; then
      printHelp

    elif [ "$1" == "socialworkertests" ]; then
      $KONFIG_PROJECTROOT/scripts/node-testing/mocha-runner "$KONFIG_PROJECTROOT/workers/social"

    elif [ "$1" == "nodeservertests" ]; then
      $KONFIG_PROJECTROOT/scripts/node-testing/mocha-runner "$KONFIG_PROJECTROOT/servers/lib/server"

    # To run specific test directory or a single test file
    elif [ "$1" == "nodetestfiles" ]; then
      $KONFIG_PROJECTROOT/scripts/node-testing/mocha-runner $2

    elif [ "$1" == "migrate" ]; then
      check_psql
      migrate $2 $3

    elif [ "$1" == "mongomigrate" ]; then
      mongomigrate $2 $3

    elif [ "$1" == "migrations" ]; then
      migrations $2 $3

    elif [ "$1" == "health-check" ]; then
      shift
      health_check "$@"

    elif [ "$1" == "switchclient" ]; then
      switch_client_version $2

    elif [ "$1" == "k8s" ]; then
      shift
      k8s "$@"

    else
      echo "Unknown command: $1"
      printHelp

    fi
    # ------ THIS FILE IS AUTO-GENERATED BY ./configure ----- #\n
    """
  return run

generateSandbox =   generateRunFile = (KONFIG) ->
  return '''
    #!/bin/bash
    export HOME=/home/ec2-user

    ENV_SHELL_FILE=${ENV_SHELL_FILE:-$(dirname $0)/.env.sh}
    if [ -f "$ENV_SHELL_FILE" ]; then
      source $ENV_SHELL_FILE
    else
      echo "error: shell environment file does not exist"
      exit 1
    fi

    COMMAND=$1
    shift

    case "$COMMAND" in
      exec) exec "$@";;
    esac

    '''
module.exports = { dev: generateDev, default: generateDev, sandbox: generateSandbox, prod: generateSandbox }
