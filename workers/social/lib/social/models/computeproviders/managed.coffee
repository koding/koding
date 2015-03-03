# Managed VMs Provider implementation for ComputeProvider
# -------------------------------------------------------

ProviderInterface = require './providerinterface'
KodingError       = require '../../error'

Regions           = require 'koding-regions'
{argv}            = require 'optimist'
KONFIG            = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class Managed extends ProviderInterface

  @ping = (client, options, callback)->

    callback null, "Managed VMs rulez #{ client.r.account.profile.nickname }!"
