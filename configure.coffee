{argv}   = require 'optimist'
{exec}   = require 'child_process'
fs       = require 'fs'
log      = console.log

options =
  config      : argv.c or 'kodingme'
  hostname    : argv.h or 'koding.local'
  region      : argv.r or 'kodingme'
  branch      : argv.b or 'cake-rewrite'
  projectRoot : argv.p or '/opt/koding'
  version     : argv.v or "1.0"
  environment : argv.e or "prod"

log "BUILDING WITH ",options

configure = (o)->

  createDataForDockerBuild = (callback)->
    exec """
    mkdir -p ./install/BUILD_DATA
    echo #{o.hostname}  >./install/BUILD_DATA/BUILD_HOSTNAME
    echo #{o.region}    >./install/BUILD_DATA/BUILD_REGION
    echo #{o.config}    >./install/BUILD_DATA/BUILD_CONFIG
    echo #{o.branch}    >./install/BUILD_DATA/BUILD_BRANCH
    echo #{o.projectRoot}    >./install/BUILD_DATA/BUILD_PROJECT_ROOT
    echo #{o.environment}    >./install/BUILD_DATA/BUILD_ENVIRONMENT
    echo #{o.version}    >./install/BUILD_DATA/BUILD_VERSION
    """,->
      log "build data is written for docker deploy."
      callback null

  checkDocker = (callback) ->
    exec "docker version",(err,stdout)->
      if stdout.indexOf("Client version:") > -1
        console.log "docker cmd found. all good."
        callback null
      else
        console.log "Please install Docker first. Exiting."
        process.exit()

  fetchDockerAuthFile = (callback) ->
    fs.readFile (process.env['HOME']+"/.dockercfg"),(err,res)->
      if err then callback "-" else callback res+""

  prepareConfigFile = (callback) ->
    configFile = require "./config/main.#{o.config}.coffee"
    configJSON = JSON.stringify(configFile,null,4)
    fs.writeFile "./install/BUILD_DATA/BUILD_CONFIG.json",configJSON,(err,res)->
      if err
        console.log "couldn't write config file. exiting."
        process.exit()
      else
        console.log "BUILD_CONFIG.json written."
        callback null             


  authToDocker = (callback) ->
    dockerAuth = '{"https://index.docker.io/v1/":{"auth":"ZGV2cmltOm45czQvV2UuTWRqZWNq","email":"devrim@koding.com"}}'
    authToken = "ZGV2cmltOm45czQvV2UuTWRqZWNq"
    fetchDockerAuthFile (file)->
      if file.indexOf(authToken) is -1
        fs.writeFile "#{process.env['HOME']}/.dockercfg",dockerAuth,(err)->
          console.log "docker file written."
          callback null
      else
        console.log "docker file correct. unchanged."
        callback null


  authToDocker (err)->
    createDataForDockerBuild ->
      prepareConfigFile ->
        log "config is written."


configure options

