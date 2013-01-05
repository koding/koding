
fs              = require 'fs'
traverse        = require 'traverse'
{EventEmitter}  = require 'events'
# t = traverse(config).paths()
  
# steps = 0
# paths = {}
# t.forEach (path)->
#   steps = path.length if path.length > steps

conf =
  path : "./config"
  types:
    prod :
      strict  : yes 
    dev :
      strict      : yes
    vagrant :
      strict      : no
      defaultsTo  : "dev"
    


class Config extends EventEmitter

  constructor : (@path)->
    @conf = conf #read file from root of the project
    @configSchemaPath = @conf.path+"/config.schema.coffee"
    @configFilePath   = @conf.path+"/"+@path+".coffee"

    @init()

  init: ->
    a = @path.split "."
    configSchema = (require @configSchemaPath)[a[0]][a[1]]
    # console.log configSchema
    configFile = require @configFilePath
    #console.log configSchema["mongo"]["databases"]["mongodb"]["0"]["password"]

    # @checkPaths configSchema,configFile

    normalizePathForSchema = (path,p=[])->
      (if n-n is 0 then path.push 0 else path.push n) for n,i in path
      return p

    paths = {}

    file   = traverse(configFile)
    schema = traverse(configSchema)
    file.paths().forEach (path)->  
      a = path.join "."
      b = paths[a] ?= {}
      b.schema = schema.has normalizePathForSchema path
      b.file   = yes


    schema.paths().forEach (path)->
      c = path.join "."
      d = paths[c] ?= {}
      d.schema = yes
      d.file   = file.has path
    
    # for i,p of paths  
    #   delete paths[i] if paths[i].schema is yes and paths[i].file is yes
    
    console.log paths




  parse : (config)->


  toJson : ->
    return @out

a = new Config "kite.databases.config-prod-new"
# a.toJson()

