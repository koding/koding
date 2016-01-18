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
 * @return {Promise}
###
listReplies = (id) -> request "/message/#{id}/reply"


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
 * @return {Promise}
###
listLikers = (id) -> request "/message/#{id}/interaction/like"


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

