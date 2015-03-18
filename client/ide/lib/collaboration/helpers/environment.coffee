kd      = require 'kd'
remote  = require('app/remote').getInstance()
sinkrow = require 'sinkrow'

###*
 * Detaches social channel of given workspace.
 *
 * @param {object} workspaceData
 * @param {function(err: object)}
###
detachSocialChannel = (workspaceData, callback) ->

  { _id } = workspaceData
  options = { $unset: channelId: 1 }
  remote.api.JWorkspace.update _id, options, (err) =>
    return callback err  if err

    workspaceData.channelId = null
    callback null


###*
 * Updates workspace with given id, with the options passed.
 *
 * @param {object} workspaceData
 * @param {object=} options
###
updateWorkspace = (workspaceData, options = {}) ->

  remote.api.JWorkspace.update workspaceData._id, { $set : options }


###*
 * Shares or unshares given machine with given users.
 *
 * @param {object} machine
 * @param {array.<string>} usernames
 * @param {boolean} share
 * @param {function(err: object)}
###
setMachineUser = (machine, usernames, share, callback) ->

  method   = if share then 'share' else 'unshare'
  jMachine = machine.getData()
  jMachine[method] usernames, (err) ->
    return callback err  if err

    kite   = machine.getBaseKite()
    method = if share then 'klientShare' else 'klientUnshare'

    queue = usernames.map (username) ->
      ->
        kite[method]({username}).then ->
          queue.fin()

        .error (err) ->
          queue.fin()

          return  if err.message is 'User not found' and not share

          callback err

    sinkrow.dash queue, callback


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

    .then (response) =>
      participants = response.split ','
      missing = usernames.filter (username) =>
        participants.indexOf(username) is -1

      return callback null, missing

    .catch callback


module.exports = {
  detachSocialChannel
  updateWorkspace
  setMachineUser
  fetchMissingParticipants
}
