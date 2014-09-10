
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class Koding extends ProviderInterface

  PLANS                =
    free               :
      total            : 1
      alwaysOn         : 0
      storage          : 3
      allowedInstances : ['t2.micro']
    hobbyist           :
      total            : 1
      alwaysOn         : 1
      storage          : 10
      allowedInstances : ['t2.micro']
    developer          :
      total            : 3
      alwaysOn         : 1
      storage          : 25
      allowedInstances : ['t2.micro']
    professional       :
      total            : 5
      alwaysOn         : 2
      storage          : 50
      allowedInstances : ['t2.micro']
    super              :
      total            : 10
      alwaysOn         : 5
      storage          : 100
      allowedInstances : ['t2.micro']


  @ping = (client, options, callback)->

    callback null, "Koding is the best #{ client.r.account.profile.nickname }!"


  @create = (client, options, callback)->

    { instanceType } = options

    meta =
      type          : "amazon"
      region        : "us-east-1"
      source_ami    : "ami-2651904e"
      instance_type : instanceType

    callback null, { meta, credential: client.r.user.username }


  @fetchUsage = (client, options, callback)->

    JMachine  = require './machine'

    { r: { group, user } } = client

    selector        = { provider: "koding" }
    selector.users  = $elemMatch: id: user.getId()
    selector.groups = $elemMatch: id: group.getId()

    JMachine.some selector, limit: 30, (err, machines)->

      return callback err  if err?

      total    = machines.length
      alwaysOn = 0
      storage  = 0

      machines.forEach (machine)->
        alwaysOn++  if machine.meta.alwaysOn
        storage += machine.meta.storage_size ? 3

      callback null, { total, alwaysOn, storage }


  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "t2.micro"
        title : "Small 1x"
        spec  : {
          cpu : 1, ram: 1, storage: 4
        }
        price : 'free'
      }
    ]