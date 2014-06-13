{argv}   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

request        = require 'request'
_ = require "underscore"

getNextApiURL = (callback)->
  return callback null, KONFIG.socialapi.proxyUrl

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
  url = "/account"
  post url, {oldId: id}, callback

createChannel = (data, callback)->
  unless data.name or data.creatorId
    return callback { message: "Request is not valid for creating channel"}
  url = "/channel"
  post url, data, callback

fetchChannelActivities = (data, callback)->
  if not data.channelId or not data.accountId
    return callback { message: "Request is not valid for creating channel"}

  url = "/channel/#{data.channelId}/history"
  get url, data, callback

fetchGroupChannels = (data, callback)->
  if not data.groupName or not data.accountId
    return callback { message: "Request is not valid for creating channel"}

  url = "/channel"
  get url, data, callback

fetchMessage = (data, callback)->
  if not data.id
    return callback { message: "Message id is not set"}

  url = "/message/#{data.id}"
  get url, data, callback

postToChannel = (data, callback)->
  if not data.channelId or not data.accountId or not data.body
    return callback { message: "Request is not valid for posting message"}

  url = "/channel/#{data.channelId}/message"
  post url, data, callback


updateLastSeenTime = (data, callback)->
  unless data.channelId and data.accountId
    return callback {message: "Request is not valid"}

  url = "/channel/#{data.channelId}/participant/#{data.accountId}/presence"
  post url, data, callback

editMessage = (data, callback)->
  if not data.body or not data.id
    return callback { message: "Request is not valid for editing a message"}

  url = "/message/#{data.id}"
  post url, data, callback

deleteMessage = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for deleting message"}
  url =  "/message/#{data.id}"
  deleteReq url, callback

likeMessage = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for liking a message"}

  url = "/message/#{data.id}/interaction/like/add"
  delete data.id
  post url, data, callback

unlikeMessage = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for unliking a message"}

  url = "/message/#{data.id}/interaction/like/delete"
  delete data.id
  post url, data, callback

listLikers = (data, callback)->
  unless data.id
    return callback { message: "Request is not valid for listing actors" }

  url = "/message/#{data.id}/interaction/like"
  delete data.id
  get url, data, callback

addReply = (data, callback)->
  if not data.accountId or not data.body or not data.messageId
    return callback { message: "Request is not valid for adding a reply"}

  url = "/message/#{data.messageId}/reply"
  post url, data, callback

listReplies = (data, callback)->
  unless data.messageId
    return callback { message: "Request is not valid for adding a reply"}

  url = "/message/#{data.messageId}/reply"
  get url, data, callback

fetchPopularTopics = (data, callback)->
  if not data.groupName or not data.type
    return callback {message: "Request is not valid for listing popular topics"}

  url = "/popular/topics/#{data.type}"
  get url, data, callback

fetchPopularPosts = (data, callback)->
  if not data.groupName or not data.type or not data.channelName
    return callback {message: "Request is not valid for listing popular topics"}

  url = "/popular/posts/#{data.channelName}/#{data.type}"
  get url, data, callback

fetchPinnedMessages = (data, callback)->
  url = "/activity/pin/list"
  get url, data, callback

pinMessage = (data, callback)->
  if not data.accountId or not data.messageId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "/activity/pin/add"
  post url, data, callback

unpinMessage = (data, callback)->
  if not data.accountId or not data.messageId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "/activity/pin/remove"
  post url, data, callback

glancePinnedPost = (data, callback)->
  if not data.accountId or not data.messageId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "/activity/pin/glance"
  post url, data, callback

followTopic = (data, callback)->
  if not data.accountId or not data.channelId
    return callback { message: "Request is not valid"}

  url = "/channel/#{data.channelId}/\
        participant/#{data.accountId}/add"
  post url, data, callback

unfollowTopic = (data, callback)->
  if not data.accountId or not data.channelId
    return callback { message: "Request is not valid"}

  url = "/channel/#{data.channelId}/\
        participant/#{data.accountId}/delete"
  post url, data, callback


fetchFollowedChannels = (data, callback)->
  if not data.accountId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "/account/#{data.accountId}/channels"
  get url, data, callback

sendPrivateMessage = (data, callback)->
  url = "/privatemessage/send"
  post url, data, callback

fetchPrivateMessages = (data, callback)->
  url = "/privatemessage/list"
  get url, data, callback

listNotifications = (data, callback)->
  if not data.accountId # or not data.groupName
    return callback {message: "Request is not valid"}

  url = "/notification/#{data.accountId}"
  get url, data, callback

glanceNotifications = (accountId, callback)->
  if not accountId
    return callback {message: "Request is not valid"}

  url = "/notification/glance"
  post url, {accountId}, callback

followUser = (data, callback)->
  followHelper data, followTopic, callback

unfollowUser = (data, callback)->
  followHelper data, unfollowTopic, callback

followHelper = (data, followFn, callback) ->
  unless data.accountId and data.creatorId
    return callback {message: "Request is not valid"}

  data.typeConstant = "followers"
  data.name = "FollowersChannelAccount-#{data.creatorId}"

  createChannel data, (err, socialApiChannel) =>
    return callback err  if err
    data.channelId = socialApiChannel.id
    followFn data, callback

createGroupNotification = (data, callback)->
  unless data.admins?.length and data.actorId and data.name
    return callback {message: "Request is not valid"}

  url = "/notification/group"
  post url, data, callback

searchTopics = (data, callback)->
  if not data.name
    return callback { message: "Name should be set for topic search"}
  url = "/channel/search"
  get url, data, callback

fetchProfileFeed = (data, callback)->
  if not data.targetId
    return callback { message: "targetId should be set"}
  url = "/account/#{data.targetId}/posts"
  get url, data, callback

messageById = (data, callback)->
  if not data.id
    return callback { message: "id should be set"}
  url = "/message/#{data.id}"
  get url, data, callback

messageBySlug = (data, callback)->
  if not data.slug
    return callback { message: "slug should be set"}
  url = "/message/slug/#{data.slug}"
  get url, data, callback

channelById = (data, callback)->
  if not data.id
    return callback { message: "id should be set"}
  url = "/channel/#{data.id}"
  get url, data, callback

channelByName = (data, callback)->
  if not data.name
    return callback { message: "name should be set"}
  url = "/channel/name/#{data.name}"
  get url, data, callback

checkChannelParticipation = (data, callback)->
  if not data.name or not data.type
    return callback { message: "request is not valid" }

  url = "/channel/checkparticipation"
  get url, data, callback

post = (url, data, callback)->
  getNextApiURL (err, apiurl)->
    return callback err if err
    request
      url    : "#{apiurl}#{url}"
      json   : true
      body   : data
      method : 'POST'
    , wrapCallback callback

deleteReq = (url, callback)->
  getNextApiURL (err, apiurl)->
    return callback err if err

    request
      url    : "#{apiurl}#{url}"
      json   : true
      method : 'DELETE'
    , wrapCallback callback

get = (url, data, callback)->
  getNextApiURL (err, apiurl)->
    return callback err if err
    request
      url    : "#{apiurl}#{url}"
      qs     : data
      json   : true
      method : 'GET'
    , wrapCallback callback

module.exports = {
  messageBySlug
  checkChannelParticipation
  messageById
  channelById
  channelByName
  glancePinnedPost
  updateLastSeenTime
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
  listReplies
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
  followUser
  unfollowUser
  createGroupNotification
}
