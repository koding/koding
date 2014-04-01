SOCIAL_API_URL = "http://localhost:8000"
request        = require 'request'

wrapCallback = (callback)->
  (err, response, body) ->
    if err or response.statusCode >= 400
      return callback body
    else
      return callback null, body

createAccount = (id, callback)->
  return callback {message:"Accont id is not valid"} unless id
  url = "#{SOCIAL_API_URL}/account"
  post url, {oldId: id}, callback

createChannel = (data, callback)->
  unless data.name or data.creatorId
    return callback { message: "Request is not valid for creating channel"}
  url = "#{SOCIAL_API_URL}/channel"
  post url, data, callback

fetchChannelActivity = (data, callback)->
  if not data.channelId or not data.accountId
    return callback { message: "Request is not valid for creating channel"}

  request
    url    : "#{SOCIAL_API_URL}/channel/#{data.channelId}/history"
    qs     : data
    json   : true
    body   : data
    method : 'GET'
  , wrapCallback callback

fetchGroupChannels = (data, callback)->
  if not data.groupName or not data.accountId
    return callback { message: "Request is not valid for creating channel"}

  request
    url    : "#{SOCIAL_API_URL}/channel"
    qs     : data
    json   : true
    body   : data
    method : 'GET'
  , wrapCallback callback

fetchMessage = (data, callback)->
  if not data.id
    return callback { message: "Message id is not set"}

  request
    url    : "#{SOCIAL_API_URL}/message/#{data.id}"
    json   : true
    method : 'GET'
  , wrapCallback callback

postToChannel = (data, callback)->
  if not data.channelId or not data.accountId or not data.body
    return callback { message: "Request is not valid for creating channel"}

  url = "#{SOCIAL_API_URL}/channel/#{data.channelId}/message"
  post url, data, callback

editMessage = (data, callback)->
  if not data.body or not data.id
    return callback { message: "Request is not valid for editing a message"}

  url = "#{SOCIAL_API_URL}/message/#{data.id}"
  post url, data, callback

deleteMessage = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for deleting message"}

  request
    url    : "#{SOCIAL_API_URL}/message/#{data.id}"
    json   : true
    method : 'DELETE'
  , wrapCallback callback

likeMessage = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for liking a message"}

  url = "#{SOCIAL_API_URL}/message/#{data.id}/interaction/like/add"
  delete data.id
  post url, data, callback

unlikeMessage = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for unliking a message"}

  url = "#{SOCIAL_API_URL}/message/#{data.id}/interaction/like/delete"
  delete data.id
  post url, data, callback

addReply = (data, callback)->
  if not data.accountId or not data.body or not data.messageId
    return callback { message: "Request is not valid for adding a reply"}

  url = "#{SOCIAL_API_URL}/message/#{data.messageId}/reply"
  post url, data, callback

post = (url, data, callback)->
  request
    url    : url
    json   : true
    body   : data
    method : 'POST'
  , wrapCallback callback

module.exports = {
  addReply
  unlikeMessage
  likeMessage
  deleteMessage
  editMessage
  postToChannel
  createAccount
  createChannel
  fetchMessage
  fetchChannelActivity
}
