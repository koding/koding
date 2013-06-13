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
kite     = require "kd-kite"
manifest = require "./manifest.json"
{spawn}  = require "child_process"
https    = require 'https' 
fs       = require 'fs-extra'
os = require 'os'
path     = require 'path'
uuid = require 'node-uuid'


class Deployment
  @pathToContainers = "/var/lib/lxc"
  constructor: (@zipUrl, @name, @lxc) ->
    @kitePath = path.join @pathToContainers, @name, "overlay", "opt", "kites"

  createLxc: (callback) ->
    cmd = spawn "create-lxc", [@kiteName]
    console.log 'create lxc'
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout: ', data.toString()
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr: ', data.toString()
    cmd.on 'close', (code) ->
      console.log 'create lxc process exited with code ', code
      callback()

  downloadAndExtractKite: (callback) ->
    {kitePath, zipUrl, kiteName} = this
    fs.mkdirsSync(kitePath) ## TODO mkdir creates 0777, exists check
    
    filepath = path.join kitePath, "#{kiteName}.zip"
    file     = fs.createWriteStream filepath

    console.log "downloading url", zipUrl, " to ", filepath
    
    request = https.get zipUrl, (response) ->
      response.pipe file
      response.on "end", () ->
        console.log "file download complete", response.statusCode
        if response.statusCode is 200
          cmd = spawn "unzip", [ path.join(@kitesPath, "#{kiteName}.zip"), "-d", @kitesPath]
          console.log 'unziping kite'
          
          cmd.stdout.on 'data', (data) ->
            #console.log 'stdout: ', data.toString()
          cmd.stderr.on 'data', (data) -> 
            #console.log 'stderr: ', data.toString()
          
          cmd.on 'close', (code) ->
            console.log 'unzip process exited with code ', code
            callback()

  runKite: () ->
    kiteInLxc = path.join "/opt", "kites", @kiteName
    runner    = path.join(@pathToContainers, @name, "overlay", "opt", "runner")
    fs.writeFileSync runner, "#!/bin/bash -l \n export HOME=/root \n /usr/sbin/kd.sh #{kiteInLxc} > /tmp/kd.out & \n"
    fs.chmodSync runner, "0755"
    cmd = spawn "/usr/bin/lxc-start", ["-d", "-n", @name]
    
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout kite : ', data.toString()
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr kite : ', data.toString()
    cmd.on 'close', (code) ->
      console.log 'lxc-execute process exited with code ', code


uuidFile = "/home/vmroot/.kd/uuid"
if fs.existsSync uuidFile
  uuid = (fs.readFileSync uuidFile).toString()
else
  uuid = uuid.v4()
  fs.writeFileSync uuidFile, uuid

console.log "deployer:", manifest.name

manifest.name = "Deployer_#{os.hostname()}_#{uuid.v4()}"
kite.worker manifest, 

  deploy: (options, callback) ->
    {id, kiteName, version, zipUrl} = options
    deployment = new Deployment(id, kiteName, zipUrl)
    deployment.create-lxc () ->
      deployment.downloadAndExtractKite deployment.runKite.bind deployment

    return callback null, "Hello, I'm #{name}! This is Deployer"


