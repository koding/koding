aws = require 'koding-aws'

buildTemplate = (callback) ->
  aws.getNextName 'generic', (err, nextName) ->
    if err
      callback err, ''
      return

    template =
      type          : 'm1.small'
      ami           : 'ami-00049b69'
      keyName       : 'koding'
      securityGroups: ['sg-e1b97189']
      tags          : [
        Key         : 'Name'
        Value       : "generic-#{nextName}-test"
      ,
        Key         : 'server_type'
        Value       : 'generic'
      ,
        Key         : 'server_id'
        Value       : nextName
      ]
      userData      : """
                      #!/bin/bash
                      route del default gw 10.0.0.1
                      route add default gw 10.0.0.63
                      """

    callback no, template

module.exports = 
  buildTemplate: buildTemplate
