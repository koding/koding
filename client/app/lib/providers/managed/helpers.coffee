kd       = require 'kd'
remote   = require 'app/remote'
globals  = require 'globals'

nick     = require 'app/util/nick'

# Not exported
getIp = (url) ->
  el = global.document.createElement 'a'
  el.href = url

  return el.hostname


queryKites = ->

  { generateQueryString } = require 'app/kite/kitecache'
  { computeController, kontrol } = kd.singletons

  # Not sure about this `default` environment as `defaultmanaged` env conv. ~GG
  env = if globals.config.environment in ['dev', 'default', 'sandbox']
  then 'dev' else ''

  return kontrol
    .queryKites
      query         :
        username    : nick()
        environment : "#{env}managed" # it's devmanaged on dev env.
    .timeout 5000
    .then (result) ->

      if result?.kites?.length
        { kites } = result
        kites.forEach (kite) ->
          kite.queryString = generateQueryString kite.kite
          kite.machine     = computeController
            .findMachineFromQueryString kite.queryString
          kite.ipAddress   = getIp kite.url
        return kites
      else
        return []


ensureManagedStack = (callback) ->

  { computeController } = kd.singletons

  title = 'Managed VMs'

  if stack = computeController.storage.stacks.get 'title', title
    return callback null, stack

  options = { title }
  remote.api.JComputeStack.create options, callback


createMachine = (kite, callback) ->

  ensureManagedStack (err, stack) ->

    return callback err  if err

    { computeController } = kd.singletons

    computeController.create {
      provider    : 'managed'
      queryString : kite.queryString
      ipAddress   : kite.ipAddress
      label       : kite.kite.hostname
      stack       : stack._id
    }, (err, machine) ->
      return callback err  if err

      if machine
        stack.machines.push machine
        computeController.storage.machines.push machine
        computeController.storage.stacks.push stack

      callback null, machine


updateMachineData = ({ machine, kite }, callback) ->

  { queryString, ipAddress } = kite
  { computeController } = kd.singletons
  computeController.update machine, { queryString, ipAddress }, callback


module.exports = {
  ensureManagedStack
  createMachine
  updateMachineData
  queryKites
}
