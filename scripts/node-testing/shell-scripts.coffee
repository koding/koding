###
# This file contains the shell scripts to be executed on the test instance(s)
###

module.exports =
  
  get     :
    
    socialWorker : (publicIpAddress) ->
      
      return "ssh -o 'StrictHostKeyChecking no' \
      -i $KODING_DEPLOYMENT_KEY \
      ubuntu@#{publicIpAddress} \
      'sudo /opt/koding/run socialworkertests'"


  asArray : (publicIpAddress) ->
    
    return [
      
      @get.socialWorker publicIpAddress
        
    ]
