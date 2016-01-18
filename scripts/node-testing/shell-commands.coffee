###
# This file contains the shell scripts to be executed on the test instance(s)
###

SSH_SCRIPT = "#{__dirname}/../test-instance/ssh"

module.exports =

  get :

    socialWorker : (publicIpAddress) ->

      return "#{SSH_SCRIPT} #{publicIpAddress} '/opt/koding/run socialworkertests'"


    nodejsWebServer : (publicIpAddress) ->

      return "#{SSH_SCRIPT} #{publicIpAddress} '/opt/koding/run nodeservertests'"


  asArray : (publicIpAddresses) ->

    return [

      @get.socialWorker publicIpAddresses.socialWorker

      @get.nodejsWebServer publicIpAddresses.nodejsWebServer

    ]
