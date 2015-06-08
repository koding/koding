###
# This file contains the shell scripts to be executed on the test instance(s)
###

module.exports =

  get     :

    socialWorker : (publicIpAddress) ->

      return "ssh -o 'StrictHostKeyChecking no' \
      -i ./scripts/test-instance/koding-test-instances-2015-06.pem \
      ubuntu@#{publicIpAddress} \
      'sudo /opt/koding/run socialworkertests'"


  asArray : (publicIpAddress) ->

    return [

      @get.socialWorker publicIpAddress

    ]
