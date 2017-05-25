_                           = require 'lodash'
kd                          = require 'kd'
async                       = require 'async'
remote                      = require 'app/remote'
socialHelpers               = require './social'


###*
 * Detaches social channel of given workspace.
 *
 * @param {object} workspaceData
 * @param {function(err: object)}
###
detachSocialChannel = (workspaceData, callback) ->

  { _id } = workspaceData
  options = { $unset: { channelId: 1 } }
  # TODOWS ~ GG - Unset channelId on JMachine
  callback null


###*
 * Shares or unshares given machine with given users.
 *
 * @param {object} machine
 * @param {object} workspace
 * @param {array.<string>} usernames
 * @param {boolean} share
 * @param {function(err: object)}
###
setMachineUser = (machine, usernames, share, callback) ->

  method = if share then 'add' else 'kick'
  channelId = machine.getChannelId()

  remote.api.Collaboration[method] channelId, usernames, (err, _machine) ->

    return callback err  if err

    kd.singletons.computeController.storage.machines.push _machine

    kite   = machine.getBaseKite()
    method = if share then 'klientShare' else 'klientUnshare'

    queue = usernames.map (username) ->
      (fin) ->
        kite[method]({ username })
        .then -> fin()
        .error (err) ->
          return  if err.message is 'User not found' and not share

          fin err

    async.parallel queue, callback


###*
 * Checks machine and finds missing participants depending on the
 * given usernames array. It then calls the callback with those missing
 * users.
 *
 * @param {object} machine
 * @param {array.<string>} usernames
 * @param {function(err: object, missingUsers: array.<string>)}
###
fetchMissingParticipants = (machine, usernames, callback) ->

  kite = machine.getBaseKite()

  kite.klientShared null

    .then (response) ->
      participants = response.split ','
      missing = usernames.filter (username) ->
        participants.indexOf(username) is -1

      return callback null, missing

    .catch callback


module.exports = {
  detachSocialChannel
  setMachineUser
  fetchMissingParticipants
}
