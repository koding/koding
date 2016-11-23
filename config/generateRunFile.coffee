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
      exit 0
      check_connectivity mongo
      check_connectivity postgres
      check_connectivity redis
      check_connectivity rabbitmq
    }

    mkdir $KONFIG_PROJECTROOT/.logs &>/dev/null

    SERVICES="mongo redis postgres rabbitmq"

    NGINX_CONF="$KONFIG_PROJECTROOT/nginx.conf"
    NGINX_PID="$KONFIG_PROJECTROOT/nginx.pid"

    #{options.requirementCommands?.join "\n"}

    trap ctrl_c INT

    function ctrl_c () {
      supervisorctl shutdown
      exit 1;
    }

    function nginxstop () {
      if [ -a $NGINX_PID ]; then
        echo "stopping nginx"
        nginx -c $NGINX_CONF -g "pid $NGINX_PID;" -s quit
      fi
    }

    function nginxrun () {
      nginxstop
      echo "starting nginx"
      nginx -c $NGINX_CONF -g "pid $NGINX_PID;"
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
      echo "  run nginx                 : to stop and restart nginx"
      echo "  run printconfig           : to print koding config environment variables (output in json via --json flag)"
      echo "  run migrate [command]     : to apply/revert database changes (command: [create|up|down|version|reset|redo|to|goto])"
      echo "  run mongomigrate [command]: to apply/revert mongo database changes (command: [create|up|down])"
      echo "  run migrations [command]  : to apply/revert mongo and postgres database changes (command: [create|up|down])"
      echo "  run nodeservertests       : to run tests for node.js web server"
      echo "  run socialworkertests     : to run tests for social worker"
      echo "  run nodetestfiles         : to run a single test or all test files in a directory"
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

      if [[ `uname` == 'Darwin' ]]; then
        if [ -z "$DOCKER_HOST" ]; then
          echo "You need to export DOCKER_HOST, run 'boot2docker up' and follow the instructions. (or run 'eval $(docker-machine env default)')"
          exit 1
        fi
      fi

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
      command -v mongo         >/dev/null 2>&1 || { echo >&2 "I require mongo but it's not installed. (brew install mongo maybe?)  Aborting."; exit 1; }
      command -v pg_isready    >/dev/null 2>&1 || { echo >&2 "I require pg_isready but it's not installed. (brew install postgresql maybe?)  Aborting."; exit 1; }
      command -v node          >/dev/null 2>&1 || { echo >&2 "I require node but it's not installed.  Aborting."; exit 1; }
      command -v npm           >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }
      command -v gulp          >/dev/null 2>&1 || { echo >&2 "I require gulp but it's not installed. (npm i gulp -g)  Aborting."; exit 1; }
      command -v coffee        >/dev/null 2>&1 || { echo >&2 "I require coffee-script but it's not installed. (npm i coffee-script -g)  Aborting."; exit 1; }
      check_psql

      if [[ `uname` == 'Darwin' ]]; then
        brew info graphicsmagick >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }
        command -v boot2docker >/dev/null 2>&1 || command -v docker-machine >/dev/null 2>&1 || { echo >&2 "I require boot2docker but it's not installed.  Aborting."; exit 1; }
      elif [[ `uname` == 'Linux' ]]; then
        command -v gm >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }
      fi

      set -o errexit

      scripts/check-node-version.sh
      scripts/check-npm-version.sh
      scripts/check-gulp-version.sh
      scripts/check-go-version.sh
      scripts/check-supervisor.sh

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
        docker run -d -p 27017:27017 --name=mongo mongo:2.4
        check_connectivity mongo
    }

    function runPostgresqlDocker () {
        docker run -d -p 5432:5432 --name=postgres koding/postgres
        check_connectivity postgres
    }

    function runRabbitMQDocker () {
        docker run -d -p 5672:5672 -p 15672:15672 --name=rabbitmq rabbitmq:3-management
        check_connectivity rabbitmq
    }

    function runRedisDocker () {
        docker run -d -p 6379:6379 --name=redis redis
    }

    function runImplyDocker () {
        docker run -d -p 18081-18110:8081-8110 -p 18200:8200 -p 19095:9095 --name=imply imply/imply:1.2.1
    }

    function run_docker_wrapper () {
      if [[ `uname` == 'Darwin' ]]; then
        command -v boot2docker >/dev/null 2>&1 && boot2docker up
        command -v docker-machine >/dev/null 2>&1 && docker-machine start default || echo 1
      fi
    }

    function build_services () {
      run_docker_wrapper

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
      restoredefaultpostgresdump

      echo "#---> CLEARING ALGOLIA INDEXES: <---#"
      pushd $KONFIG_PROJECTROOT
      ./scripts/clear-algolia-index.sh -i "accounts$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"
      ./scripts/clear-algolia-index.sh -i "topics$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"
      ./scripts/clear-algolia-index.sh -i "messages$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"

      nginxrun
    }

    function services () {

      run_docker_wrapper

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

      nginxrun
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

    function restoreimply () {
      removeDockerByName imply
      runImplyDocker
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

      printconfig $@

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

    elif [ "$1" == "nginx" ]; then
      nginxrun

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

    elif [ "$1" == "janitortests" ]; then
      pushd $KONFIG_PROJECTROOT/go/src/koding/workers/janitor
      ./test.sh

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

    else
      echo "Unknown command: $1"
      printHelp

    fi
    # ------ THIS FILE IS AUTO-GENERATED BY ./configure ----- #\n
    """
  return run

generateSandbox =   generateRunFile = (KONFIG) ->
  return """
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

    """
module.exports = { dev: generateDev, default: generateDev, sandbox: generateSandbox, prod: generateSandbox }
