traverse              = require 'traverse'
log                   = console.log
fs                    = require 'fs'
os                    = require 'os'
path                  = require 'path'
{ isAllowed }         = require '../deployment/grouptoenvmapping'

generateDev = (KONFIG, options) ->

  options.requirementCommands ?= []

  installScript = """
      pushd $KONFIG_PROJECTROOT
      git submodule update --init

      npm install --unsafe-perm

      echo '#---> BUILDING CLIENT <---#'
      make -C $KONFIG_PROJECTROOT/client unit-tests

      echo '#---> BUILDING GO WORKERS (@farslan) <---#'
      $KONFIG_PROJECTROOT/go/build.sh

      echo '#---> BUILDING SOCIALAPI (@cihangir) <---#'
      pushd $KONFIG_PROJECTROOT/go/src/socialapi
      make configure
      # make install
      cleanchatnotifications

      echo '#---> AUTHORIZING THIS COMPUTER WITH MATCHING KITE.KEY (@farslan) <---#'
      KITE_KEY=$KONFIG_KITEHOME/kite.key
      mkdir $HOME/.kite &>/dev/null
      echo copying $KITE_KEY to $HOME/.kite/kite.key
      cp -f $KITE_KEY $HOME/.kite/kite.key

      echo
      echo
      echo 'ALL DONE. Enjoy! :)'
      echo
      echo
  """

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

    mkdir $KONFIG_PROJECTROOT/.logs &>/dev/null

    SERVICES="mongo redis postgres rabbitmq imply"

    NGINX_CONF="$KONFIG_PROJECTROOT/nginx.conf"
    NGINX_PID="$KONFIG_PROJECTROOT/nginx.pid"

    #{options.requirementCommands?.join "\n"}

    trap ctrl_c INT

    function ctrl_c () {
      supervisorctl shutdown
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

    function migrations () {
      # a temporary migration line (do we still need this?)
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

      # Check if PG DB schema update required
      go run $KONFIG_PROJECTROOT/go/src/socialapi/tests/pg-update.go $KONFIG_POSTGRES_HOST $KONFIG_POSTGRES_PORT
      RESULT=$?

      if [ $RESULT -ne 0 ]; then
        exit 1
      fi

      # Update node modules
      if ! scripts/check-node_modules.sh; then
        npm install --silent
      fi

      # Check everything else
      check

      # Remove old watcher files (do we still need this?)
      rm -rf $KONFIG_PROJECTROOT/go/bin/goldorf-main-*
      rm -rf $KONFIG_PROJECTROOT/go/bin/watcher-*

      # Run Go builder
      $KONFIG_PROJECTROOT/go/build.sh

      # Run Social Api builder
      make -C $KONFIG_PROJECTROOT/go/src/socialapi configure

      # Do PG Migration if necessary
      migrate up

      # Sanitize email addresses
      node $KONFIG_PROJECTROOT/scripts/sanitize-email

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
      echo "  run resetdb               : to reset databases"
      echo "  run services              : to stop and restart services"
      echo "  run worker                : to list workers"
      echo "  run printconfig           : to print koding config environment variables (output in json via --json flag)"
      echo "  run worker [worker]       : to run a single worker"
      echo "  run migrate [command]     : to apply/revert database changes (command: [create|up|down|version|reset|redo|to|goto])"
      echo "  run importusers           : to import koding user data"
      echo "  run nodeservertests       : to run tests for node.js web server"
      echo "  run socialworkertests     : to run tests for social worker"
      echo "  run nodetestfiles         : to run a single test or all test files in a directory"
      echo "  run sanitize-email        : to sanitize email"
      echo "  run help                  : to show this list"
      echo ""

    }

    function migrate () {
      migrations

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

    function check (){

      check_service_dependencies

      if [[ `uname` == 'Darwin' ]]; then
        if [ -z "$DOCKER_HOST" ]; then
          echo "You need to export DOCKER_HOST, run 'boot2docker up' and follow the instructions."
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
      command -v go            >/dev/null 2>&1 || { echo >&2 "I require go but it's not installed.  Aborting."; exit 1; }
      command -v docker        >/dev/null 2>&1 || { echo >&2 "I require docker but it's not installed.  Aborting."; exit 1; }
      command -v nginx         >/dev/null 2>&1 || { echo >&2 "I require nginx but it's not installed. (brew install nginx maybe?)  Aborting."; exit 1; }
      command -v mongorestore  >/dev/null 2>&1 || { echo >&2 "I require mongorestore but it's not installed.  Aborting."; exit 1; }
      command -v node          >/dev/null 2>&1 || { echo >&2 "I require node but it's not installed.  Aborting."; exit 1; }
      command -v npm           >/dev/null 2>&1 || { echo >&2 "I require npm but it's not installed.  Aborting."; exit 1; }
      command -v gulp          >/dev/null 2>&1 || { echo >&2 "I require gulp but it's not installed. (npm i gulp -g)  Aborting."; exit 1; }
      # command -v stylus      >/dev/null 2>&1 || { echo >&2 "I require stylus  but it's not installed. (npm i stylus -g)  Aborting."; exit 1; }
      command -v coffee        >/dev/null 2>&1 || { echo >&2 "I require coffee-script but it's not installed. (npm i coffee-script -g)  Aborting."; exit 1; }
      check_psql

      if [[ `uname` == 'Darwin' ]]; then
        brew info graphicsmagick >/dev/null 2>&1 || { echo >&2 "I require graphicsmagick but it's not installed.  Aborting."; exit 1; }
        command -v boot2docker   >/dev/null 2>&1 || { echo >&2 "I require boot2docker but it's not installed.  Aborting."; exit 1; }
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

    function build_services () {

      if [[ `uname` == 'Darwin' ]]; then
        boot2docker up
      fi

      echo "Stopping services: $SERVICES"
      docker stop $SERVICES

      echo "Removing services: $SERVICES"
      docker rm   $SERVICES

      # Build Mongo service
      pushd $KONFIG_PROJECTROOT/install/docker-mongo
      docker build -t koding/mongo .

      # Build postgres
      pushd $KONFIG_PROJECTROOT/go/src/socialapi/db/sql

      # Include this to dockerfile before we continute with building
      mkdir -p kontrol
      cp $KONFIG_PROJECTROOT/go/src/github.com/koding/kite/kontrol/*.sql kontrol/
      sed -i -e "s/somerandompassword/$KONFIG_KONTROL_POSTGRES_PASSWORD/" kontrol/001-schema.sql
      sed -i -e "s/kontrolapplication/$KONFIG_KONTROL_POSTGRES_USERNAME/" kontrol/001-schema.sql

      docker build -t koding/postgres .

      docker run -d -p 27017:27017                                        --name=mongo    koding/mongo --dbpath /data/db --smallfiles --nojournal
      docker run -d -p 5672:5672 -p 15672:15672                           --name=rabbitmq rabbitmq:3-management

      docker run -d -p 6379:6379                                          --name=redis    redis
      docker run -d -p 5432:5432                                          --name=postgres koding/postgres

      docker run -d -p 18081-18110:8081-8110 -p 18200:8200 -p 19095:9095  --name=imply    imply/imply:1.2.1
      restoredefaultmongodump

      echo "#---> CLEARING ALGOLIA INDEXES: @chris <---#"
      pushd $KONFIG_PROJECTROOT
      ./scripts/clear-algolia-index.sh -i "accounts$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"
      ./scripts/clear-algolia-index.sh -i "topics$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"
      ./scripts/clear-algolia-index.sh -i "messages$KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX"

      migrate up
    }

    function services () {

      if [[ `uname` == 'Darwin' ]]; then
        boot2docker up
      fi
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


    function importusers () {

      node $KONFIG_PROJECTROOT/scripts/user-importer -c dev
      migrateusers

    }

    function migrateusers () {

      echo '#---> UPDATING MONGO DB TO WORK WITH SOCIALAPI @cihangir <---#'
      mongo $KONFIG_MONGO --eval='db.jAccounts.update({},{$unset:{socialApiId:0}},{multi:true}); db.jGroups.update({},{$unset:{socialApiChannelId:0}},{multi:true});'

      go run $KONFIG_PROJECTROOT/go/src/socialapi/workers/cmd/migrator/main.go -c $KONFIG_SOCIALAPI_CONFIGFILEPATH

      # Required step for guestuser
      mongo $KONFIG_MONGO --eval='db.jAccounts.update({"profile.nickname":"guestuser"},{$set:{type:"unregistered", socialApiId:0}});'

    }

    function restoredefaultmongodump () {

      echo '#---> CREATING VANILLA KODING DB @gokmen <---#'

      mongo $KONFIG_MONGO --eval "db.dropDatabase()"

      pushd $KONFIG_PROJECTROOT/install/docker-mongo
      if [[ -f $KONFIG_PROJECTROOT/install/docker-mongo/custom-db-dump.tar.bz2 ]]; then
        tar jxvf $KONFIG_PROJECTROOT/install/docker-mongo/custom-db-dump.tar.bz2
      else
        tar jxvf $KONFIG_PROJECTROOT/install/docker-mongo/default-db-dump.tar.bz2
      fi

      read HOST _ DB <<<"$(echo $KONFIG_MONGO | awk -F '[:/]' '{ print $1, $2, $3}')"
      mongorestore --host $HOST --db $DB dump/koding

      rm -rf ./dump

      updatePermissions

    }

    function updatePermissions () {

      echo '#---> UPDATING MONGO DATABASE ACCORDING TO LATEST CHANGES IN CODE (UPDATE PERMISSIONS @gokmen) <---#'
      node $KONFIG_PROJECTROOT/scripts/permission-updater -c dev --reset

    }

    function updateusers () {

      node $KONFIG_PROJECTROOT/scripts/user-updater

    }

    function cleanchatnotifications () {
      $GOBIN/notification -c $KONFIG_SOCIALAPI_CONFIGFILEPATH -h
    }

    if [ "$#" == "0" ]; then
      checkrunfile
      run $1

    elif [ "$1" == "docker-compose" ]; then
      shift
      docker_compose

    elif [ "$1" == "exec" ]; then
      shift
      exec "$@"

    elif [ "$1" == "install" ]; then
      check_service_dependencies
      #{installScript}

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

    elif [ "$1" == "updatepermissions" ]; then
      updatePermissions

    elif [ "$1" == "resetdb" ]; then

      if [ "$2" == "--yes" ]; then

        env PGPASSWORD=social_superuser psql -tA -h $KONFIG_POSTGRES_HOST $KONFIG_POSTGRES_DBNAME -U social_superuser -c "DELETE FROM \"api\".\"channel_participant\"; DELETE FROM \"api\".\"channel\";DELETE FROM \"api\".\"account\";"
        restoredefaultmongodump
        migrateusers

        exit 0

      fi

      read -p "This will reset current databases, all data will be lost! (y/N)" -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
          exit 1
      fi

      env PGPASSWORD=social_superuser psql -tA -h $KONFIG_POSTGRES_HOST $KONFIG_POSTGRES_DBNAME -U social_superuser -c "DELETE FROM \"api\".\"channel_participant\"; DELETE FROM \"api\".\"channel\";DELETE FROM \"api\".\"account\";"
      restoredefaultmongodump
      migrateusers

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
      migrate up

    elif [ "$1" == "help" ]; then
      printHelp

    elif [ "$1" == "importusers" ]; then
      importusers

    elif [ "$1" == "updateusers" ]; then
      updateusers

    elif [ "$1" == "cleanchatnotifications" ]; then
      cleanchatnotifications

    elif [ "$1" == "worker" ]; then

      if [ "$2" == "" ]; then
        echo Available workers:
        echo "-------------------"
        supervisorctl status | awk '${print $1} | sort'
      else
        trap - INT
        trap
        exec supervisorctl start $2
      fi

    elif [ "$1" == "migrate" ]; then
      check_psql

      if [ -z "$2" ]; then
        echo "Please choose a migrate command [create|up|down|version|reset|redo|to|goto]"
        echo ""
      else
        pushd $GOPATH/src/socialapi
        make install-migrate
        migrate $2 $3
      fi

    elif [ "$1" == "vmwatchertests" ]; then
      go test koding/vmwatcher -test.v=true

    elif [ "$1" == "janitortests" ]; then
      pushd $KONFIG_PROJECTROOT/go/src/koding/workers/janitor
      ./test.sh

    elif [ "$1" == "gatheringestortests" ]; then
      go test koding/workers/gatheringestor -test.v=true

    elif [ "$1" == "gomodeltests" ]; then
      go test koding/db/mongodb/modelhelper -test.v=true

    elif [ "$1" == "socialworkertests" ]; then
      $KONFIG_PROJECTROOT/scripts/node-testing/mocha-runner "$KONFIG_PROJECTROOT/workers/social"

    elif [ "$1" == "nodeservertests" ]; then
      $KONFIG_PROJECTROOT/scripts/node-testing/mocha-runner "$KONFIG_PROJECTROOT/servers/lib/server"

    # To run specific test directory or a single test file
    elif [ "$1" == "nodetestfiles" ]; then
      $KONFIG_PROJECTROOT/scripts/node-testing/mocha-runner $2

    elif [ "$1" == "sanitize-email" ]; then
      node $KONFIG_PROJECTROOT/scripts/sanitize-email

    elif [ "$1" == "migrations" ]; then
      migrations

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
