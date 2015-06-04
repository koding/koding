fs = require 'fs'

module.exports =
  
  getNthInstanceData : (instanceData, n) ->
    
    # getting nth test instance's id and public ip
    instance = {}
    
    [ instance.instanceId, instance.publicIpAddress ] = fs.readFileSync instanceData
      .toString().split("\n")[n].split(' ')
      
    return instance
    

