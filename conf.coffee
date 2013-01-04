
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
    configSchema = (require @configSchemaPath)[a[0]]
    # console.log configSchema
    configFile = require @configFilePath
    @checkPaths configSchema,configFile

  checkPaths:(obj1,obj2) ->
    t1 = traverse(obj1).paths()
    t1.forEach (path)=>
      o = @checkVal path,obj1,obj2 unless path.length is 0
        
    t2 = traverse(obj2).paths()
    t2.forEach (path)=>
      o = @checkVal path,obj2,obj1 unless path.length is 0

  checkVal:(path,obj1,obj2)->
    p = path.join "."
    r     = {}
    r.key = p
    try
      eval("r.val1 = obj1."+p)
    catch e
      # console.log "a. Property mismatch between #{@configSchemaPath} and #{@configFilePath}: #{p}"
    try
      eval("r.val2 = obj2."+p)
    catch e
      console.log "b. Property mismatch between #{@configSchemaPath} and #{@configFilePath}: #{p}"
    if r.val is 1
      console.log r
      return r
    else if Array.isArray(r.val)
      console.log r
      return r



  parse : (config)->


  toJson : ->
    return @out

a = new Config "main.prod"
# a.toJson()

