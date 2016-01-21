_                           = require 'lodash'
kd                          = require 'kd'
remote                      = require('app/remote').getInstance()
sinkrow                     = require 'sinkrow'
socialHelpers               = require './social'
userEnvironmentDataProvider = require 'app/userenvironmentdataprovider'


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
 * @param {object} workspace
 * @param {array.<string>} usernames
 * @param {boolean} share
 * @param {function(err: object)}
###
setMachineUser = (machine, workspace, usernames, share, callback) ->

  method = if share then 'add' else 'kick'

  remote.api.Collaboration[method] workspace.getId(), usernames, (err) ->
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


isUserStillParticipantOnMachine = (options, callback) ->

  { username, machineUId } = options

  remote.cacheable username, (err, accounts) ->

    return callback no  if err
    return callback no  unless accounts.length

    { socialApiId } = accounts.first

    userEnvironmentDataProvider.fetchWorkspacesByMachineUId machineUId, (workspaces) ->

      workspaces = workspaces.filter (w) -> w  if w.channelId

      socialHelpers.fetchParticipantsCollaborationChannels socialApiId, (err, channels) ->

        return callback no  if err

        anyActiveSession = no

        workspaces.forEach (w) ->
          channel = _.find channels, _id : w.channelId
          anyActiveSession = yes  if channel

        callback anyActiveSession


module.exports = {
  detachSocialChannel
  updateWorkspace
  setMachineUser
  fetchMissingParticipants
  isUserStillParticipantOnMachine
}
