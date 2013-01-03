
fs = require 'fs'
traverse = require 'traverse'
config = require './config/main.dev.coffee'


t = traverse(config).paths()
  
steps = 0
paths = {}
t.forEach (path)->
  steps = path.length if path.length > steps
  for node,key in path
    paths

types =
  path : "./config/main.vagrant.coffee"
  types:
    prod :
      strict  : yes 
    dev :
      strict      : yes
    vagrant :
      strict      :no
      defaultsTo  : "dev"
  


class Config


  constructor : (options)->



console.log steps

