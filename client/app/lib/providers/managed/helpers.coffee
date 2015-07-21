kd      = require 'kd'
nick    = require 'app/util/nick'
Machine = require '../machine'


# Not exported
getIp = (url)->
  el = global.document.createElement 'a'
  el.href = url

  return el.hostname


queryKites = ->

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


createMachine = (kite, callback)->

  { computeController } = kd.singletons

  stack = computeController.stacks.first._id

  computeController.create {
    provider    : 'managed'
    queryString : kite.queryString
    ipAddress   : kite.ipAddress
    label       : kite.kite.hostname
    stack
  }, callback


updateMachineData = ({machine, kite}, callback)->

  { queryString, ipAddress } = kite
  { computeController } = kd.singletons
  computeController.update machine, {queryString, ipAddress}, callback


module.exports = {
  createMachine
  updateMachineData
  queryKites
}


