option '-C', '--buildClient', 'override buildClient flag with yes'
option '-c', '--configFile [CONFIG]', 'What config file to use.'
option '-s', '--dontBuildSprites', 'dont build sprites'
option '-g', '--evengo', 'pass evengo to corresponding command'
option '-r', '--region [REGION]', 'region flag'
option '-w', '--worker [WORKER]', 'run a specific worker'
option '-i', '--IP [IP]', 'vm IP'
option '-h', '--hostname [HOSTNAME]', 'hostname'
option '-p', '--password [PASSWORD]', 'vm Pass'
option '-b', '--branch [BUILD_BRANCH]', 'build branch'


require 'colors'

require('coffee-script').register()
{argv}            = require 'optimist'
{exec}            = require 'child_process'
processes         = new (require "processes") main : true
{daisy}           = require 'sinkrow'
nodePath          = require 'path'
fs                = require 'fs'
{exec}            = require 'child_process'

timethat          = require 'timethat'
hat               = require 'hat'
log = console.log
# Watcher           = require 'koding-watcher'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")
publicKey         = fs.readFileSync(process.env['HOME']+"/.ssh/id_rsa.pub")


task 'killall','',->

  exec "bash ./install/killall.sh", (err,cuf,cif)->
    console.log arguments
  

checkConfig = (options,callback=->)->
  console.log "[KONFIG CHECK] If you don't see any errors, you're fine."
  require('koding-config-manager').load("main.#{options.configFile}")
  require('koding-config-manager').load("kite.applications.#{options.configFile}")
  require('koding-config-manager').load("kite.databases.#{options.configFile}")
    
    

# importDB = (options, callback = ->)->
#   return callback null unless options.configFile in ['vagrant', 'kodingme']  
#   exec "bash ./install/createBlankMongo.sh", (err, stdout, stderr)->
#     console.log stdout
#     console.error stderr if stderr          
#     callback null



task 'buildLocally',(options)->

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




  checkDocker (err) ->
    unless err
      authToDocker (err)->
        configFile = JSON.stringify require "./config/main.#{options.configFile}.coffee"
        console.log configFile

        processes.run """
          mkdir -p ./install/BUILD_DATA
          echo #{options.hostname} >./install/BUILD_DATA/BUILD_HOSTNAME
          echo #{options.region}   >./install/BUILD_DATA/BUILD_REGION
          echo #{options.configFile}   >./install/BUILD_DATA/BUILD_CONFIG
          echo #{options.branch}   >./install/BUILD_DATA/BUILD_BRANCH
        """
        ,->
          log "yup"

task 'o',->
  console.log "s"

task 'rs',-> 
  eden = require 'node-eden'
  RS = require 'pkgcloud'
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
        # console.log vm
        adminPass = vm.adminPass
        progress = setInterval ->
          rs.compute.getServer vm.id,(err,vm) ->            
            console.log "creating #{options.name} #{vm.progress}% complete." if prg isnt vm.progress
            prg = vm.progress
            if vm.progress is 100
              end = new Date()
              console.log "creating #{options.name} took "+ timethat.calc start,end
              # console.log vm
              vm.adminPass = adminPass
              clearInterval progress
              callback null, vm
        ,1000
      else
        callback err
  getPublicIP = (server)->
    return val.addr for val,key in server.addresses.public when val.version is 4
  
  ### DNS ###

  # rs.dns.getZones -> console.log arguments
  # console.dir rs.dns
  # rs.dns.getRecords "4255573",-> 
  #   console.log arguments
  
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

            console.log "A RECORD #{domainName} -> #{publicIP} is placed with TTL 3600."
            console.log "Server password is #{server.adminPass}"
            console.log "Server is now ready at ssh root@#{domainName}"
            
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
  #     console.log server.addresses.public


  # rs.getFlavors (err,flavors)->
  #   # console.log flavors
  #   for val,key in flavors
  #     console.log val.id

  # rs.getImages (err,images)->
  # # console.log images
  #   for val,key in images
  #     console.log val.id,val.name

  
task "konnect",'',-> 
  konnect 
    IP        : argv.i 
    username  : "root"
    password  : argv.p
    hostname  : argv.h
    region    : "kodingme"
    config    : "kodingme"
    branch    : "cake-rewrite"

konnect = (options,callback) ->

  {IP,username,password, hostname, region, config,branch} = options

  Connection = require("ssh2")
  conn = new Connection()
  
  conn.on "ready", ->
    console.log "Connection :: ready"  
    conn.sftp (err, sftp) ->
      throw err if err
      sftp.fastPut "./install/Dockerfile","/root/Dockerfile", (err, res) ->
        throw err if err
        sftp.fastPut "./install/dockerbuild.sh","/root/dockerbuild.sh", (err, res) ->
          throw err if err    
          console.log "building..."
          conn.exec "mkdir /root/.ssh && echo #{publicKey} >> /root/.ssh/authorized_keys", (err, str) ->
            str.on "close", -> console.log "Your public key is added to the box, you don't need a password."

            conn.exec "bash /root/dockerbuild.sh #{hostname} #{region} #{config} #{branch}", (err, stream) ->
              throw err  if err
              stream.on "exit", (code, signal) -> console.log "Stream :: exit :: code: " + code + ", signal: " + signal
              stream.on "close", -> 
                console.log "Box is ready at: ssh root@#{hostname} pubkey is added, no need for passwd:#{password})" 
                conn.end()
              stream.on "data", (data) -> console.log (data+"").replace("\n","")
  
  conn.connect
    host         : IP
    port         : 22
    username     : username
    # privateKey   : require("fs").readFileSync(process.env['HOME']+"/.ssh/id_rsa")
    # publicKey    : publicKey
    readyTimeout : 60000
    password     : password




task 'run', (options)->
  process.stdout.setMaxListeners 100
  process.stderr.setMaxListeners 100

  if options.worker
    if KONFIG[options.worker]?.process?.run
      KONFIG[options.worker].process.name = options.worker
      processes.spawn KONFIG[options.worker].process
    else
      console.log "no such worker."
  else  
    for key,val of KONFIG when val?.process?.run
      val.process.name = key
      console.log "RUN:"+key
      # processes.spawn val.process



buildEverything = (options, callback = ->)->

  exec "./go/build.sh",(err,stdout,stderr)->
    console.log arguments
    daisy queue = [
      ->
        oldIndex = nodePath.join __dirname, "website/index.html"
        fs.unlinkSync oldIndex  if fs.existsSync oldIndex
        queue.next()
    ,
      ->
        if options.buildClient
          options.callback = -> queue.next()
          buildClient options
        else
          queue.next()
    ,
      -> callback null
    ]


task 'buildEverything', "Build everything and exit.", (options)->

  options.buildClient = yes
  options.watch = no
  buildEverything options

buildClient = (options)->
  buildMethod = if options.dontBuildSprites then 'buildClient' else 'buildSprites'
  (new (require('./Builder')))[buildMethod] options


task 'buildClient', "Build the static web pages for webserver", (options)-> buildClient options
task 'deleteCache', "Delete the local webserver cache", (options)-> (exec "rm -rf #{__dirname}/.build",-> console.log "Cache is pruned.")

task 'cleanup', "Removes every cache, and file which is not committed yet", (options)->
  sure = if options.yes then "" else "-n"
  evengo = if options.evengo then "" else "-e go"
  exec "git clean -d -f #{sure} -x -e .vagrant -e node_modules -e node_modules_koding #{evengo}", (err, res)->
    if res isnt ''
      console.log "\n\n#{res}"
      unless options.yes
        console.log "If you are sure to remove these files run:\n\n  $ cake --yes cleanup \n"
        console.warn "Doing `vagrant halt` is recommended before cleanup!"
      else
        console.log "All remaining files removed, it's a new era for you!\n"
    else
      console.log "Everything seems fine, nothing to remove."




# doApi = new (require 'digitalocean-api')('2d314ba76e8965c451f62d7e6a4bc56f', '4c88127b50c0c731aeb5129bdea06deb')
# task 'DO',->
#   # doApi.domainNew "koding.io", "1.1.1.1", (err,res)-> console.log res
#   doApi.imageGetAll (err,res)-> console.log arguments
#   # doApi.sizeGetAll (err,res)-> console.log arguments
#   # doApi.sshKeyGetAll (err,res)->  console.log arguments  
#   # doApi.domainGetAll (err,res)-> console.log res
#   # doApi.domainRecordNew 325644, "A", "1.1.1.1", {name:"devrim.koding.io"}, (err,res)-> console.log err, res
#   # doApi.domainRecordNew 325644, "A", droplet.ip_address, {name:domainName}, (err,res)-> 
# task 'y',->
#   konnect "162.243.137.6","root","",->
#     console.log "donnnnee."



# task 'droplet',"",->
#   eden = require('node-eden')
#   cf = require('cloudflare').createClient
#     email: 'devrim@kodingen.com',
#     token: '14102694c54ad092c62265d45f90c797d7927'
# 
#   # doApi.imageGetAll (err,res)-> console.log arguments
#   # doApi.sizeGetAll (err,res)-> console.log arguments
#   # doApi.sshKeyGetAll (err,res)->  console.log arguments
#   # size ids: 512mb = 66 64gb = 69
#   # ubuntu image id 3240036 - LAMP id 3961756 - koding-installer 4395492
#   subdomain  = eden.eve().toLowerCase()
#   domainName = subdomain+".koding.me"
# 
#   doApi.sshKeyAdd domainName, publicKey+"", (err,sshKey)->
#     imageId = 3240036
#     if err
#       console.log err
#     else
#       console.log "publicKey with id #{sshKey.id} is added. creating droplet..."
#       doApi.dropletNew domainName, 69, imageId, 3, { ssh_key_ids: [sshKey.id], private_networking: false, backups_enabled: false }, (err,newDroplet)->
#       # doApi.dropletNew domainName, 66,3961756, 3,{}, (err,res)->
#         if err
#           console.log "[ERROR]", err
#           return null
#         #console.log "droplet:", res
# 
#         perc = 0
#         instancePoll = setInterval ->
# 
#           doApi.eventGet newDroplet.event_id,(err,event)->
# 
#             if perc isnt event.percentage
#               console.log  "creating #{domainName} "+event.percentage+"% done"
#               perc = event.percentage          
# 
#             if event.percentage is "100" 
#               clearInterval instancePoll
# 
#               doApi.dropletGet event.droplet_id,(err,droplet)->
#                 if err
#                   console.log "[error] creating #{domainName}",err
#                 else
#                   console.log "droplet is ready: "+domainName                     
#                   cf.addDomainRecord 'koding.me',
#                     type    : "A"
#                     name    : subdomain
#                     content : droplet.ip_address
#                     , (err,cfRecord) ->
#                       console.log "Cloudflare record added A:#{domainName} -> #{droplet.ip_address}"
#                       unless err
#                         console.log "droplet is ready."
#                         console.log "ssh root@"+domainName
#                         console.log "ssh root@"+droplet.ip_address
#                         setTimeout ->                      
#                           konnect droplet.ip_address,"root","",->
#                             console.log "done"
#                         ,10000
#         ,1000


# task "cleanDroplets","",->
# 
#   doApi.dropletGetAll (err,droplets)->
#     # console.log droplets
#     
#     droplets.forEach (droplet)->
# 
#       if droplet.name.indexOf("cihangir.koding.me") isnt 0
#         if droplet.name.indexOf("koding.me") isnt -1 or 
#         droplet.name.indexOf("koding.io") isnt -1 or
#         droplet.name.indexOf("koding.dvr") isnt -1 or
#         droplet.name.indexOf("devrim-") isnt -1 or
#         droplet.name.indexOf("koding-") isnt -1 or
#         droplet.name.indexOf("cache-") isnt -1 or
#         droplet.name.indexOf("gokmen-") isnt -1        
#           doApi.dropletDestroy droplet.id,(err,res)->
#             unless err then console.log "#{droplet.name} is destroyed"
#             else console.log "-error destroying " + droplet.name
#         else console.log "skipping "+droplet.name
#       else console.log "skipping "+droplet.name
# 
# 



