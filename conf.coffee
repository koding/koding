
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
    @emit "start"
    @conf = conf #read file from root of the project
    @configSchemaPath = @conf.path+"/config.schema.coffee"
    @configFilePath   = @conf.path+"/"+@path+".coffee"

    @check()

  check: ->
    a = @path.split "."
    configSchema = (require @configSchemaPath)[a[0]][a[1]]
    configFile = require @configFilePath

    normalizePathForSchema = (path,p=[])->
      (if n-n is 0 then p.push 0 else p.push n) for n,i in path
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
    
    
    (delete paths[i] if paths[i].schema is yes and paths[i].file is yes) for i,p of paths
    
    

    process.nextTick =>
      @emit "errors",paths      
      


  parse : (config)->


  toJson : ->
    return @out

config = new Config "kite.databases.config-prod-new"
config.on "errors",(paths)->

















