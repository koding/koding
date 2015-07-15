nick = require 'app/util/nick'
kd   = require 'kd'


# The maximum number of heartbeat attempts when looking for
# a new kite.
MAX_HEARTBEATS = 60
# The default heartbeat interval, in seconds.
HEARTBEAT_INTERVAL = 5


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


###*
 * Repeatedly queryKites at the rate of interval (per second) until
 * a kite is found.
 *
 * @param {Number} interval - The heartbeat interval (in seconds).
 * @param {Function(err:Error, info:Object)} callback - A callback for
 *  when the new kite is connected. Info is the returned object from
 *  the klient kite's `klient.info` method. This contains the
 *  `providerName` key, among other things.
###
heartbeatKites = (interval = HEARTBEAT_INTERVAL, callback = kd.noop) ->

  { router, computeController } = kd.singletons

  beatCount  = 0
  oldKites   = {}
  intervalId = null

  # A callback wrapper, to help ensure clearInterval is always called
  kallback = (err, info) ->

    # It's expected that clearInterval gets called twice, but that
    # is not a problem in Chrome at least.
    clearInterval intervalId
    callback err, info

  # Called on every interval, until canceled
  heartbeat = ->

    beatCount++
    if beatCount > MAX_HEARTBEATS
      return kallback new Error "Maximum heartbeat limit of
        #{MAX_HEARTBEATS} reached."

    queryPromise = queryKites()
    queryPromise.then (kites) ->
      # No kites ready, wait for another heartbeat
      return unless kites?.length

      clearInterval intervalId

      # Check the old kites vs the new kites
      newKite = null
      for kite in kites
        if oldKites[kite.keyId]
          newKite = kite
          break

      # If there is no newKite, return and wait for another heartbeat
      unless newKite
        return

      createMachine newKite, (err, machine) ->
        return kallback err  if err

        # Route to the IDE
        kd.utils.defer -> router.handleRoute "/IDE/#{machine.slug}"

        # Get the klient kite, and the info from that klient so we
        # can popup a Provider specific modal
        # TODO: Is there a better way to get the klient kite?
        klient = computeController.machinesById[machine._id].getBaseKite()
        klient.klientInfo().nodeify kallback

    queryPromise.catch (err) ->
      kallback err  if err

  # First, query for the kites to find the original kites
  # After that's done, start the heartbeat.
  queryKites()
    .then (kites = []) ->
      oldKites[kite.keyId] = kite  for kite in kites
      intervalId = setInterval heartbeat, interval * 1000
      # Call the heartbeat immediately *after* setInterval,
      # so we can clear it if it is immediately available.
      heartbeat()
    .catch (err) ->
      kallback err
  return


module.exports = {
  createMachine
  heartbeatKites
  updateMachineData
  queryKites
}


