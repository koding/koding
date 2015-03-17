nick = require 'app/util/nick'
kd   = require 'kd'

getIp = (url)->
  _ = global.document.createElement 'a'
  _.href = url

  return _.hostname


module.exports =

  queryKites: ->

    { generateQueryString } = require 'app/kite/kitecache'
    { computeController, kontrol } = kd.singletons

    return kontrol
      .queryKites
        query         :
          username    : nick()
          environment : 'managed'
      .timeout 5000
      .then (result)->

        if result?.kites?.length
          {kites} = result
          kites.forEach (kite)->
            kite.queryString = generateQueryString kite.kite
            kite.machine     = computeController
              .findMachineFromQueryString kite.queryString
            kite.ipAddress   = getIp kite.url
          return kites
        else
          return []


  createMachine: (kite, callback)->

    { computeController } = kd.singletons

    stack = computeController.stacks.first._id

    computeController.create {
      provider    : 'managed'
      queryString : kite.queryString
      ipAddress   : kite.ipAddress
      stack
    }, callback


  updateMachineData: ({machine, kite}, callback)->

    options       =
      machineId   : machine._id
      provider    : 'managed'
      queryString : kite.queryString
      ipAddress   : kite.ipAddress

    remote = require('app/remote').getInstance()
    remote.api.ComputeProvider.update options, callback
