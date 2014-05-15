{argv}   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

SOCIAL_API_URL = KONFIG.socialApiUrl
request        = require 'request'

wrapCallback = (callback)->
  (err, response, body) ->
    if err
      if err.code is "ECONNREFUSED"
        return callback {message: "Social API is currently under maintenance"}
      return callback err

    if response.statusCode >= 400
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

fetchChannelActivities = (data, callback)->
  if not data.channelId or not data.accountId
    return callback { message: "Request is not valid for creating channel"}

  url = "#{SOCIAL_API_URL}/channel/#{data.channelId}/history"
  get url, data, callback

fetchGroupChannels = (data, callback)->
  if not data.groupName or not data.accountId
    return callback { message: "Request is not valid for creating channel"}

  url = "#{SOCIAL_API_URL}/channel"
  get url, data, callback

fetchMessage = (data, callback)->
  if not data.id
    return callback { message: "Message id is not set"}

  url = "#{SOCIAL_API_URL}/message/#{data.id}"
  get url, data, callback

postToChannel = (data, callback)->
  if not data.channelId or not data.accountId or not data.body
    return callback { message: "Request is not valid for posting message"}

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

listLikers = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for listing actors" }

  url = "#{SOCIAL_API_URL}/message/#{data.id}/interaction/like"
  delete data.id
  get url, data, callback

addReply = (data, callback)->
  if not data.accountId or not data.body or not data.messageId
    return callback { message: "Request is not valid for adding a reply"}

  url = "#{SOCIAL_API_URL}/message/#{data.messageId}/reply"
  post url, data, callback

fetchPopularTopics = (data, callback)->
  if not data.groupName or not data.type
    return callback {message: "Request is not valid for listing popular topics"}

  url = "#{SOCIAL_API_URL}/popular/topics/#{data.type}"
  get url, data, callback

fetchPopularPosts = (data, callback)->
  if not data.groupName or not data.type or not data.channelName
    return callback {message: "Request is not valid for listing popular topics"}

  url = "#{SOCIAL_API_URL}/popular/posts/#{data.channelName}/#{data.type}"
  get url, data, callback

fetchPinnedMessages = (data, callback)->
  url = "#{SOCIAL_API_URL}/activity/pin/list"
  get url, data, callback

pinMessage = (data, callback)->
  if not data.accountId or not data.messageId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/activity/pin/add"
  post url, data, callback

unpinMessage = (data, callback)->
  if not data.accountId or not data.messageId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/activity/pin/remove"
  post url, data, callback

followTopic = (data, callback)->
  if not data.accountId or not data.channelId
    return callback { message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/channel/#{data.channelId}/\
        participant/#{data.accountId}/add"
  post url, data, callback

unfollowTopic = (data, callback)->
  if not data.accountId or not data.channelId
    return callback { message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/channel/#{data.channelId}/\
        participant/#{data.accountId}/delete"
  post url, data, callback


fetchFollowedChannels = (data, callback)->
  if not data.accountId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/account/#{data.accountId}/channels"
  get url, data, callback

sendPrivateMessage = (data, callback)->
  url = "#{SOCIAL_API_URL}/privatemessage/send"
  post url, data, callback

fetchPrivateMessages = (data, callback)->
  url = "#{SOCIAL_API_URL}/privatemessage/list"
  get url, data, callback

listNotifications = (data, callback)->
  if not data.accountId # or not data.groupName
    return callback {message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/notification/#{data.accountId}"
  get url, data, callback

glanceNotifications = (accountId, callback)->
  if not accountId
    return callback {message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/notification/glance"
  post url, {accountId}, callback

createFollowNotification = (data, callback)->
  unless data.accountId and data.targetId
    return callback {message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/notification/follow"
  post url, data, callback

createGroupNotification = (data, callback)->
  unless data.admins?.length and data.actorId and data.name
    return callback {message: "Request is not valid"}

  url = "#{SOCIAL_API_URL}/notification/group"
  post url, data, callback

searchTopics = (data, callback)->
  if not data.name
    return callback { message: "Name should be set for topic search"}
  url = "#{SOCIAL_API_URL}/channel/search"
  get url, data, callback

fetchProfileFeed = (data, callback)->
  if not data.targetId
    return callback { message: "targetId should be set"}
  url = "#{SOCIAL_API_URL}/account/#{data.targetId}/posts"
  get url, data, callback

post = (url, data, callback)->
  request
    url    : url
    json   : true
    body   : data
    method : 'POST'
  , wrapCallback callback

get = (url, data, callback)->
  request
    url    : url
    qs     : data
    json   : true
    method : 'GET'
  , wrapCallback callback

module.exports = {
  fetchProfileFeed
  searchTopics
  fetchPrivateMessages
  sendPrivateMessage
  fetchFollowedChannels
  followTopic
  unfollowTopic
  fetchPinnedMessages
  pinMessage
  unpinMessage
  fetchPopularPosts
  fetchPopularTopics
  addReply
  unlikeMessage
  likeMessage
  listLikers
  deleteMessage
  editMessage
  postToChannel
  createAccount
  createChannel
  fetchMessage
  fetchChannelActivities
  fetchGroupChannels
  listNotifications
  glanceNotifications
  createFollowNotification
  createGroupNotification
}
