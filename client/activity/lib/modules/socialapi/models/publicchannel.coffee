_ = require 'lodash'
{ request } = require '../utils'

###*
 * Create a post to given channel id.
 *
 * @param {String} id
 * @param {Object} data
 * @param {Object} data.body
 * @param {Object} data.payload
 * @param {Object} data.clientRequestId
 * @return {Promise}
###
post = (id, data) ->
  request "/channel/#{id}/message", {method: 'post', data}


###*
 * Send a message to given channel id.
 *
 * @param {String} id
 * @param {Object} data
 * @param {Object} data.body
 * @param {Object} data.payload
 * @param {Object} data.clientRequestId
 * @param {Array} data.participants ????
 * @return {Promise}
###
sendMessage = (id, data) ->
  data = _.assign {}, data, {channelId: id}
  request "/channel/sendwithparticipants", {method: post, data}


module.exports = {
  post
  sendMessage
}


