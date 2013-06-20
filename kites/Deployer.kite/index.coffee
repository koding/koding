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

manifest.name = "Deployer_#{os.hostname()}_#{deployerId}"
console.log "deployer:", manifest.name
kite.worker manifest, 

  deploy: (options, callback) ->
    {kiteName, version, zipUrl} = options
    deployment = new Deployment(kiteName, version, zipUrl)
    deployment.createLxc () ->
      deployment.downloadAndExtractKite deployment.runKite.bind deployment

    return callback null, "Hello, This is #{manifest.name}"


