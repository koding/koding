fs = require 'fs'

getNthInstanceData = (instanceData, n) ->
  
  # getting nth test instance's id and public ip
  instance = {}
  
  [ instance.instanceId, instance.publicIpAddress ] = fs.readFileSync instanceData
    .toString().split("\n")[n].split(' ')
    
  return instance


getNthInstancePublicIpAddress = (instanceData, n) ->

  return getNthInstanceData(instanceData, n).publicIpAddress

    
module.exports = {
  getNthInstanceData
  getNthInstancePublicIpAddress
}
  

