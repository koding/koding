#!/usr/bin/env coffee

Connection = require "ssh2"
{argv}     = require 'optimist'
log        = console.log
eden       = require 'node-eden'
RS         = require './install/pkgcloud'
hat        = require 'hat'
timethat   = require 'timethat'


options =
  config      : argv.c or 'kodingme'
  hostname    : argv.h or 'koding.local'
  region      : argv.r or 'kodingme'
  branch      : argv.b or 'cake-rewrite'
  projectRoot : argv.p or '/opt/koding'
  version     : argv.v or "1.0"
  environment : argv.e or "prod"
  target      : argv.t or "rackspace"


deploy = () -> 
  rs = 
    compute : RS.compute.createClient
      provider  : 'rackspace'
      username  : "kodinginc"
      apiKey    : "96d6388ccb936f047fd35eb29c36df17"
      region    : 'IAD'

    dns : RS.dns.createClient
      provider  : 'rackspace'
      username  : "kodinginc"
      apiKey    : "96d6388ccb936f047fd35eb29c36df17"

  createServer = (options,callback)->
    start = new Date()
    rs.compute.createServer options,(err,vm)->
      unless err
        prg = 0
        # log vm
        adminPass = vm.adminPass
        progress = setInterval ->
          rs.compute.getServer vm.id,(err,vm) ->            
            log "creating #{options.name} #{vm.progress}% complete." if prg isnt vm.progress
            prg = vm.progress
            if vm.progress is 100
              end = new Date()
              log "creating #{options.name} took "+ timethat.calc start,end
              # log vm
              vm.adminPass = adminPass
              clearInterval progress
              callback null, vm
        ,1000
      else
        callback err
  getPublicIP = (server)->
    return val.addr for val,key in server.addresses.public when val.version is 4
  
  ### DNS ###

  # rs.dns.getZones -> log arguments
  # console.dir rs.dns
  # rs.dns.getRecords "4255573",-> 
  #   log arguments
  
  subdomain  = eden.eve().toLowerCase()
  domainName = subdomain+".koding.me"
  password   = hat()
  createServer
    name   : domainName
    flavor : 'performance2-90'  
    image  : 'bb02b1a3-bc77-4d17-ab5b-421d89850fca'  #ubuntu 14.04
    personality: []
    (err,server)->
      if err then throw err
      else
        publicIP = getPublicIP server
        rs.dns.createRecord "4255573",
          name : domainName
          type : "A"
          ttl  : "3600"
          data : publicIP
          (err,rec)->

            log "A RECORD #{domainName} -> #{publicIP} is placed with TTL 3600."
            log "Server password is #{server.adminPass}"
            log "Server is now ready at ssh root@#{domainName}"
            
            setTimeout ->
              konnect 
                IP        : publicIP
                username  : "root"
                password  : server.adminPass
                hostname  : domainName
                region    : "kodingme"
                config    : "kodingme"
                branch    : "cake-rewrite"            
            ,10000
          
  # some useful extras for later.
  # rs.getServers (err,servers)-> 
  #   for server,index in servers
  #     log server.addresses.public


  # rs.getFlavors (err,flavors)->
  #   # log flavors
  #   for val,key in flavors
  #     log val.id

  # rs.getImages (err,images)->
  # # log images
  #   for val,key in images
  #     log val.id,val.name

listen = (op, stream, callback)->
  stream.on "data", (data)         -> log ("[#{op}] #{data}").replace("\n","")
  stream.on "exit", (code, signal) -> log "[#{op}] did exit."
  stream.on "close",               -> 
    log "[#{op}] did close."
    callback null,"close"

sftpCopy = (options, callback)->
  copyCount = 1
  results = []
  options.conn.sftp (err, sftp) ->
    for file,nr in options.files
      do (file)->
        sftp.fastPut file.src,file.trg,(err,res)->
          throw err if err
          if copyCount is options.files.length then callback null,"done"
          copyCount++


konnect = (options,callback) ->

  {IP,username,password, hostname, region, config,branch} = options
  conn = new Connection()

  conn.connect
    host         : IP
    port         : 22
    username     : username
    # privateKey   : require("fs").readFileSync(process.env['HOME']+"/.ssh/id_rsa")
    # publicKey    : publicKey
    readyTimeout : 60000
    password     : password

  
  conn.on "ready", ->
    log "Connection :: ready"  

    copyFiles = [
      { src: "./install/prepare"                        , dst: "/root/prepare"},
      { src: "./configure"                              , dst: "/root/configure"},
      { src: "./install/run/docker.prod/Dockerfile"     , dst: "/root/Dockerfile"},
      { src: "./install/run/docker.sh"                  , dst: "/root/docker.sh"}
    ]

    sftpCopy conn : conn, files : copyFiles,(err,res)->
      conn.exec "/root/prepare -h #{hostname} -r #{region} -c #{config} -b #{branch}", (err, stream) ->
        throw err  if err
        listen "[configuring server]", stream,-> 
          log "Box is ready at: ssh root@#{hostname} pubkey is added, no need for passwd:#{password})" 
          conn.end

deploy()
