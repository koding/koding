###
# This file contains the shell scripts to be executed on the test instance(s)
###

pemFilePath = './scripts/test-instance/koding-test-instances-2015-06.pem'

module.exports =

  get :

    socialWorker : (publicIpAddress) ->

      return "ssh -o 'StrictHostKeyChecking no' \
      -i #{pemFilePath} \
      ubuntu@#{publicIpAddress} \
      'sudo /opt/koding/run socialworkertests'"


    nodejsWebServer : (publicIpAddress) ->

      return "ssh -o 'StrictHostKeyChecking no' \
      -i #{pemFilePath} \
      ubuntu@#{publicIpAddress} \
      'sudo /opt/koding/run nodeservertests'"


  asArray : (publicIpAddresses) ->

    return [

      @get.socialWorker publicIpAddresses.socialWorker

      @get.nodejsWebServer publicIpAddresses.nodejsWebServer

    ]
