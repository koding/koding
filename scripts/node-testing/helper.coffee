fs = require 'fs'

getNthInstanceData = (instanceData, n) ->
  
  instance = null
  
  # getting nth test instance's id and public ip
  nthInstanceData = fs.readFileSync(instanceData).toString().split("\n")[n]?.split(' ')

  if nthInstanceData
    instance = {}
    [ instance.instanceId, instance.publicIpAddress ] = nthInstanceData
    
  return instance


getNthInstancePublicIpAddress = (instanceData, n) ->

  # returns null if nth instance data doesn't exist
  return getNthInstanceData(instanceData, n)?.publicIpAddress


currentInstanceIndex = 0

getNextInstancePublicIpAddress = (instanceData) ->

  ipAddress = switch
    when getNthInstancePublicIpAddress instanceData, currentInstanceIndex + 1
      getNthInstancePublicIpAddress instanceData, currentInstanceIndex++
    else
      getNthInstancePublicIpAddress instanceData, currentInstanceIndex

  return ipAddress


module.exports = {
  getNthInstanceData
  getNthInstancePublicIpAddress
  getNextInstancePublicIpAddress
}
  

