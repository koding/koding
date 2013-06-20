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
redis = require 'redis'
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
    console.log 'create lxc'
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

  runKite: () ->
    kiteInLxc = path.join "/opt", "kites", @kiteName
    runner    = path.join Deployment.pathToContainers, @lxcId, "overlay", "opt", "runner"
    console.log runner
    fs.writeFileSync runner, "#!/bin/bash -l \n export HOME=/root \n /usr/bin/kd kite run #{kiteInLxc} > /tmp/kd.out & \n"
    fs.chownSync runner, 500000, 500000
    fs.chmodSync runner, "0755"
    cmd = spawn "/usr/bin/lxc-start", ["-d", "-n", @lxcId]
    
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout kite : ', data.toString()
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr kite : ', data.toString()
    cmd.on 'close', (code) ->
      console.log 'lxc-execute process exited with code ', code


deployerIdFile = "/home/vmroot/.kd/deployerId"
if fs.existsSync deployerIdFile
  deployerId = (fs.readFileSync deployerIdFile).toString()
else
  deployerId = uuid.v4()
  fs.writeFileSync deployerIdFile, deployerId

manifest.name = "Deployer"
manifest.uuid = deployerId
console.log "deployer:", manifest.name
console.log "Kite", Kite


deploys = []

kite.worker manifest, 

  report: (args)->
    o = {id: @communicator.getChannelNameForKite(), deployCnt: deploys.length}
    console.log "reporting:::::", o
    return [o]

  who: (args, callback)->
    kites = []
    @all "report", [], (kiteId)->
      console.log ">>>>>>>>>", kiteId
      kites.push kiteId
    # if anyone hasn't replied in 3 seconds just dont care
    # about them, either they are busy, or dead
    setTimeout ()->
      callback null, kites
    , 3000

  doDeploy: (options)->
    console.log "now doing the deploy", options
    deploys.push options
    return ["Hello, This is #{manifest.name}"]

    # {kiteName, version, zipUrl} = options
    # deployment = new Deployment(kiteName, version, zipUrl)
    # deployment.createLxc () ->
    #   deployment.downloadAndExtractKite deployment.runKite.bind deployment
    #   deploys.push deployment.deployId
    # return callback null, "Hello, This is #{manifest.name}"

  deploy: (options, callback) ->

    who = (args, callback)=>
      kites = []
      @all "report", [], (kiteId)->
        kites.push kiteId
      # if anyone hasn't replied in 3 seconds just dont care
      # about them, either they are busy, or dead
      setTimeout ()->
        callback null, kites
      , 300

    findBestDeployer = (deployers)->
      if not deployers
        throw new Error "no deployers", deployers
      if deployers.length > 0
        last = 0
        for d in deployers
          console.log "d.deployCnt:::", d.deployCnt, last, d
          if d.deployCnt <= last
            best = d
          last = d.deployCnt

        console.log "====================="
        console.log best
        console.log "====================="
        if not best
          best = deployers[0]
        return best

    who [], (err, kites)=>
      bestKite = findBestDeployer(kites)
      console.log "sending options:::: ", options
      @one bestKite.kiteName, 'doDeploy', [options], (args)->
        console.log "[[[[[[[[ doDeploy returned yay .....", args
        callback(bestKite) 



