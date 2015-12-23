fs = require 'fs'

getNthInstanceData = (instanceData, n) ->
  
  instance = {}
  
  # getting nth test instance's id and public ip
  nthInstanceData = fs.readFileSync(instanceData).toString().split("\n")[n]?.split(' ')

  if nthInstanceData
    [ instance.instanceId, instance.publicIpAddress ] = nthInstanceData
    
  return instance


getNthInstancePublicIpAddress = (instanceData, n) ->

  # returns null if nth instance data doesn't exist
  return getNthInstanceData(instanceData, n).publicIpAddress

    
module.exports = {
  getNthInstanceData
  getNthInstancePublicIpAddress
}
  

