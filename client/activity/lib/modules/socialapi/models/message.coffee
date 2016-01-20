{ request } = require '../utils'

###*
 * Fetch message with id.
 *
 * @param {String} id
 * @return {Promise}
###
byId = (id) -> request "/message/#{id}"


###*
 * Fetch message with slug.
 *
 * @param {String} slug
 * @return {Promise}
###
bySlug = (slug) -> request "/message/slug/#{slug}"


###*
 * Destroy message with id.
 *
 * @param {String} id
 * @return {Promise}
###
destroy = (id) -> request "/message/#{id}", {method: 'delete'}


###*
 * Update message with id.
 *
 * @param {String} id
 * @param {Object} data
 * @return {Promise}
###
update = (id, data) -> request "/message/#{id}", {method: 'post', data}


###*
 * FIXME: What to put here? or remove completely?
###
create = ->
  # message are being created via `channel.post` request method.
  #


# reply related

###*
 * List replies of a message with id.
 *
 * @param {String} id
 * @param {Object=} data
 * @return {Promise}
###
listReplies = (id, data = {}) -> request "/message/#{id}/reply", {data}


###*
 * Create a reply to a message with id.
 *
 * @param {String} id
 * @param {Object} data
 * @return {Promise}
###
reply = (id, data) -> request "/message/#{id}/reply", {method: 'post', data}


# like related

###*
 * Fetch message with id.
 *
 * @param {String} id
 * @param {Object=} data
 * @return {Promise}
###
listLikers = (id, data = {}) -> request "/message/#{id}/interaction/like", {data}


###*
 * Fetch message with id.
 *
 * @param {String} id
 * @return {Promise}
###
like = (id) -> request "/message/#{id}/interaction/like/add", {method: 'post'}


###*
 * Fetch message with id.
 *
 * @param {String} id
 * @return {Promise}
###
unlike = (id) ->

  return request "/message/#{id}/interaction/like/delete", {method: 'post'}


module.exports = {
  byId
  bySlug
  destroy
  update
  create
  listReplies
  reply
  listLikers
  like
  unlike
}

