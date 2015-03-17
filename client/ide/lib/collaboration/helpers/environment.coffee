kd     = require 'kd'
remote = require('app/remote').getInstance()

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


module.exports = {
  detachSocialChannel
  updateWorkspace
}
