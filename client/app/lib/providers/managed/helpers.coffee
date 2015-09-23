kd      = require 'kd'
remote  = require('app/remote').getInstance()
Machine = require '../machine'

nick     = require 'app/util/nick'
isKoding = require 'app/util/isKoding'

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


fetchStack = (callback) ->

  { computeController } = kd.singletons

  if isKoding()
    return callback null, computeController.stacks.first

  title = 'Managed VMs'

  for stack in computeController.stacks when stack.title is title
    return callback null, stack

  options = { title }
  remote.api.JComputeStack.create options, callback


createMachine = (kite, callback)->

  fetchStack (err, stack) ->

    return callback err  if err

    { computeController } = kd.singletons

    computeController.create {
      provider    : 'managed'
      queryString : kite.queryString
      ipAddress   : kite.ipAddress
      label       : kite.kite.hostname
      stack       : stack._id
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
