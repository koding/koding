_ = require 'lodash'
{ request } = require '../utils'
whoami = require 'app/util/whoami'

###*
 * Create a private channel.
 *
 * @param {Object} data
 * @param {Array.<JAccount._id>} data.recipients
 * @param {String} data.string
 * @return {Promise}
###
init = (data) ->

  data = _.assign (_.omit data, 'channelId')

  return request '/privatechannel/init', {method: 'post', data}


###*
 * Send message to a private channel
 *
 * @param {String} id - private channel id
 * @param {Object} data - request data
 * @param {String} data.body
 * @return {Promise}
###
send = (id, data) ->

  data = _.assign {}, data, {channelId: id}

  return request '/privatechannel/send', {method: 'post', data}


###*
 * List private channels.
 *
 * @return {Promise}
###
list = -> request '/privatechannel/list'


###*
 * List private channels matching given name.
 *
 * @param {String} name
 * @return {Promise}
###
search = (name) ->

  return request '/privatechannel/search', {method: 'post', data: {name}}


module.exports = {
  init
  send
  list
  search
}
