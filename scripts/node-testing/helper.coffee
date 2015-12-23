fs = require 'fs'

getNthInstanceData = (instanceData, n) ->
  
  # getting nth test instance's id and public ip
  instance = null
  
  nthInstanceData = fs.readFileSync(instanceData).toString().split("\n")[n]?.split(' ')

  if nthInstanceData
    instance = {}
    [ instance.instanceId, instance.publicIpAddress ] = nthInstanceData
    
  return instance


getNthInstancePublicIpAddress = (instanceData, n) ->

  return getNthInstanceData(instanceData, n)?.publicIpAddress

    
module.exports = {
  getNthInstanceData
  getNthInstancePublicIpAddress
}
  

