
ProviderInterface = require './providerinterface'
KodingError       = require '../../error'
JVM               = require '../vm'

{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class Koding extends ProviderInterface


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