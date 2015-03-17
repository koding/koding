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
 * @param {string} id
 * @param {object=} options
###
updateWorkspace = (id, options = {}) ->

  remote.api.JWorkspace.update id, { $set : options }


module.exports = {
  detachSocialChannel
  updateWorkspace
}
