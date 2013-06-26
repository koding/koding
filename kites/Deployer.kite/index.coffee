###
#
#  Deployer Kite for Koding
#  Author: armagankim 
#
#  This is an example kite with two methods:
#
#    - helloWorld
#    - fooBar
#
###
redis    = require 'redis'
kite     = require "kite-amqp/lib/kite-amqp/kite.coffee"
Kite     = require "kite-amqp/lib/kite-amqp/index.coffee"
manifest = require "./manifest.json"
{spawn}  = require "child_process"
https    = require 'https' 
fs       = require 'fs-extra'
os       = require 'os'
path     = require 'path'
uuid     = require 'node-uuid'
wrench   = require 'wrench'


class Deployment
  @pathToContainers = "/var/lib/lxc"
  constructor: (@kiteName, @version, @zipUrl) ->
    @deployId = uuid.v4()
    @lxcId = "#{@kiteName}-#{@version}-#{@deployId}"
    @kitePath = path.join Deployment.pathToContainers, @lxcId, "overlay", "opt", "kites"

  createLxc: (callback) ->
    cmd = spawn "/usr/sbin/create-lxc", [@lxcId]
    console.log 'create lxc', "/usr/sbin/create-lxc", @lxcId
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout: ', data.toString()
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr: ', data.toString()
    cmd.on 'close', (code) ->
      console.log 'create lxc process exited with code ', code
      callback()

  downloadAndExtractKite: (callback) ->
    {kitePath, zipUrl, version, kiteName} = this
    fs.mkdirsSync kitePath ## TODO mkdir creates 0777, exists check
    
    filepath = path.join kitePath, "#{kiteName}.zip"
    file     = fs.createWriteStream filepath

    console.log "downloading url", zipUrl, " to ", filepath
    
    request = https.get zipUrl, (response) ->
      response.pipe file
      response.on "end", () ->
        console.log "file download complete", response.statusCode
        if response.statusCode is 200
          cmd = spawn "unzip", [ path.join(kitePath, "#{kiteName}.zip"), "-d", kitePath]
          console.log 'unziping kite'
          
          cmd.stdout.on 'data', (data) ->
            #console.log 'stdout: ', data.toString()
          cmd.stderr.on 'data', (data) -> 
            #console.log 'stderr: ', data.toString()
          
          cmd.on 'close', (code) ->
            console.log 'unzip process exited with code ', code
            manifestFilePath = path.join(kitePath, kiteName, "manifest.json")
            content = JSON.parse fs.readFileSync(manifestFilePath)
            content.version = version
            fs.writeFileSync manifestFilePath, JSON.stringify(content)
            wrench.chownSyncRecursive kitePath, 500000, 500000
            callback()

  runKiteInStrippedContainer: () ->
    # this starts container/vm and then the kite
    kiteInLxc = path.join "/opt", "kites", @kiteName
    runner    = path.join Deployment.pathToContainers, @lxcId, "overlay", "opt", "runner"
    console.log runner
    fs.writeFileSync runner, "#!/bin/bash\nexport HOME=/root \n/usr/bin/kd kite run #{kiteInLxc}\n"
    fs.chownSync runner, 500000, 500000
    fs.chmodSync runner, "0755"
    cmd = spawn "/usr/bin/lxc-start", ["-n", @lxcId, "/opt/runner"]
    
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout kite : ', data.toString()
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr kite : ', data.toString()
    cmd.on 'close', (code) ->
      console.log 'lxc-execute process exited with code ', code

  runKite: () ->
    # this starts a full blown container/vm
    kiteInLxc = path.join "/opt", "kites", @kiteName
    runner    = path.join Deployment.pathToContainers, @lxcId, "overlay", "opt", "runner"
    console.log runner
    fs.writeFileSync runner, "#!/bin/bash\nexport HOME=/root \n/usr/bin/kd kite run #{kiteInLxc} > /tmp/kd.out & \n"
    fs.chownSync runner, 500000, 500000
    fs.chmodSync runner, "0755"
    cmd = spawn "/usr/bin/lxc-start", ["-d", "-n", @lxcId]
    
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout kite : ', data.toString()
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr kite : ', data.toString()
    cmd.on 'close', (code) ->
      console.log 'lxc-execute process exited with code ', code


deployerIdFile = "/root/.kd/deployerId"
if fs.existsSync deployerIdFile
  deployerId = (fs.readFileSync deployerIdFile).toString()
else
  deployerId = uuid.v4()
  fs.writeFileSync deployerIdFile, deployerId

manifest.name = "Deployer"
manifest.uuid = deployerId

deploys = []
kite.worker manifest, 

  report: (args, cb)->
    o = {id: @communicator.getChannelNameForKite(), deployCnt: deploys.length}
    return cb(false, o)

  who: (args, callback)->
    kites = []
    @all "report", [], (err, kiteId)->
      console.log "kiteId", kiteId
      kites.push kiteId
    # if anyone hasn't replied in 3 seconds just dont care
    # about them, either they are busy, or dead
    setTimeout ()->
      callback null, kites
    , 3000

  doDeploy: (options, callback)->
    console.log "now doing the deploy", options.args[0]
    {kiteName, version, url} = options.args[0]
    deployment = new Deployment(kiteName, version, url)
    deployment.createLxc () ->
      deployment.downloadAndExtractKite deployment.runKite.bind deployment
      deploys.push options
      return callback false, "deployed to #{manifest.name} #{manifest.uuid}"


  deploy: (options, callback) ->

    who = (args, cb)=>
      kites = []
      console.log "deploy.who called???"
      @all "report", [], (err, opts)->
        console.log "deploy.who: ", arguments
        kites.push opts.args[1]
      # if anyone hasn't replied in 500msec just dont care
      # about them, either they are busy, or dead
      setTimeout ()->
        cb null, kites
      , 500

    findBestDeployer = (deployers)->
      if not deployers or deployers.length==0
        throw new Error "no deployers", deployers

      console.log "findBestDeployer>>", deployers
      if deployers.length > 0
        last = 0
        for d in deployers
          if d.deployCnt <= last
            best = d
          last = d.deployCnt
        if not best
          best = deployers[0]
        return best

    who [], (err, kites)=>
      bestKite = findBestDeployer(kites)
      @one bestKite.id, 'doDeploy', options.args, (args)->
        console.log "doDeploy returned.....", args
        callback(bestKite) 



