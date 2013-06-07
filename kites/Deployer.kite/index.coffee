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
https = require 'https' 
fs = require 'fs-extra'
path = require 'path'

class LXC
  
  constructor: (@name) ->
    @pathToContainers = "/var/lib/lxc"
    console.log "......LXC constructor",  @name

  createLxc: (callback) ->
    cmd = spawn "create-lxc", [@name]
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout: ', data
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr: ', data
    cmd.on 'close', (code) ->
      console.log 'child process exited with code ', code
      callback()

class Deployment
  constructor: (@zipUrl, @name, @lxc) ->
    console.log "......Deployment constructor",  @lxc
    @kitePath = path.join @lxc.pathToContainers, @lxc.name, "overlay", "opt", "kites", @lxc.name

  downloadAndExtractKite: (callback) ->
      fs.mkdirsSync(@kitePath) ## TODO mkdir creates 0777, exists check
      file = fs.createWriteStream @kitePath
      request = https.get @zipUrl, (response) ->
        response.pipe file
      callback()

  runKite: () ->
    cmd = spawn "/usr/bin/lxc-execute /bin/bash -c \" cd #{@kitePath} && /usr/bin/kd kite run #{@name}\""
    cmd.stdout.on 'data', (data) ->
      console.log 'stdout: ', data
    cmd.stderr.on 'data', (data) -> 
      console.log 'stderr: ', data
    cmd.on 'close', (code) ->
      console.log 'child process exited with code ', code

kite.worker manifest, 
  # This is a dummy method of the kite.
  deploy: (options, callback) ->
    console.log options
    {zipUrl, name} = options
    console.log name, zipUrl
    lxc = new LXC(name)
    lxc.createLxc () ->
      deployment = new Deployment(zipUrl, name, lxc)
      deployment.downloadAndExtractKite deployment.runKite

    return callback null, "Hello, I'm #{name}! This is Deployer"


