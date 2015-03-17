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
          callback null
          queue.fin()

        .error (err) ->
          queue.fin()
          callback err

    sinkrow.dash queue, callback


module.exports = {
  detachSocialChannel
  updateWorkspace
  setMachineUser
}
