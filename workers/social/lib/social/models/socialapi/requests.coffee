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

createAccount = ({id, nickname}, callback)->
  if not id or not nickname
    return callback {message:"Request is not valid for creating account"}
  url = "/account"
  post url, {oldId: id, nick: nickname}, callback

createChannel = (data, callback)->
  unless data.name or data.creatorId
    return callback { message: "Request is not valid for creating channel"}
  url = "/channel"
  post url, data, callback

fetchChannelActivities = (data, callback)->
  if not data.channelId or not data.accountId
    return callback { message: "Request is not valid for fetching activities"}
  url = "/channel/#{data.channelId}/history"
  get url, data, callback

fetchActivityCount = (data, callback)->
  if not data.channelId
    return callback {message: "Request is not valid for fetching activity count"}

  url = "/channel/#{data.channelId}/history/count"
  get url, data, callback

fetchGroupChannels = (data, callback)->
  if not data.groupName or not data.accountId
    return callback { message: "Request is not valid for fetching channel"}

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

listParticipants = (data, callback)->
  return callback { message: "Request is not valid" } unless data.channelId
  url = "/channel/#{data.channelId}/participants"
  get url, data, callback

addParticipants = (data, callback)->
  url = "/channel/#{data.channelId}/participants/add"
  doChannelParticipantOperation data, url, callback

removeParticipants = (data, callback)->
  url = "/channel/#{data.channelId}/participants/remove"
  doChannelParticipantOperation data, url, (err, response) ->
    return callback err if err
    cycleChannelHelper data, response
    callback null, response

cycleChannelHelper = (data, removeResult)->
  return unless removeResult?.length

  isUserRemoved = (removeResult) ->
    for accountResult in removeResult
      return yes  if accountResult.statusConstant is 'left'

    return no

  return unless isUserRemoved removeResult

  {channelId, accountId} = data
  channelById {id: channelId, accountId}, (err, channel) ->
    return console.error err if err
    return console.error 'Channel not found' unless channel?.channel
    {channel} = channel
    options =
      groupSlug     : channel.groupName
      apiChannelType: channel.typeConstant
      apiChannelName: channel.name
    SocialChannel = require './channel'
    SocialChannel.cycleChannel options, (err) ->
      return console.error err if err


doChannelParticipantOperation = (data, url, callback)->
  return callback { message: "Request is not valid" } unless data.channelId

  # if accountIds is not set and also accountId is not set
  # return error
  if not data.accountIds
    return callback { message: "Request is not valid" } if not data.accountId
    data.accountIds = [data.accountId]

  # make the object according to channel participant data
  req = ({accountId} for accountId in data.accountIds)

  url = "#{url}?accountId=#{data.accountId}"
  post url, req, callback

updateLastSeenTime = (data, callback)->
  unless data.channelId and data.accountId
    return callback {message: "Request is not valid"}

  url = "/channel/#{data.channelId}/participant/#{data.accountId}/presence"
  post url, data, callback

fetchFollowedChannels = (data, callback)->
  if not data.accountId or not data.groupName
    return callback { message: "Request is not valid"}

  url = "/account/#{data.accountId}/channels"
  get url, data, callback

initPrivateMessage = (data, callback)->
  if not data.body or not data.recipients or data.recipients.length < 1
    return callback { message: "Request is not valid"}

  url = "/privatemessage/init"
  post url, data, callback

sendPrivateMessage = (data, callback)->
  if not data.body or not data.channelId
    return callback { message: "Request is not valid"}

  url = "/privatemessage/send"
  post url, data, callback

fetchPrivateMessages = (data, callback)->
  url = "/privatemessage/list"
  get url, data, callback

followUser = (data, callback)->
  followHelper data, addParticipants, callback

unfollowUser = (data, callback)->
  followHelper data, removeParticipants, callback

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
  # accountId is appended in doRequest.
  delete data.accountId
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

markAsTroll = (data, callback)->
  unless data.accountId
    return callback {message: "Request is not valid"}

  url = "/trollmode/#{data.accountId}"
  post url, data, callback

unmarkAsTroll = (data, callback)->
  unless data.accountId
    return callback {message: "Request is not valid"}

  url = "/trollmode/#{data.accountId}"
  deleteReq url, callback

getSiteMap = (data, callback)->
  url = data.name
  getXml url, {}, callback

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

getXml = (url, data, callback)->
  getNextApiURL (err, apiurl)->
    return callback err if err
    request
      url    : "#{apiurl}#{url}"
      method : 'GET'
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
  unmarkAsTroll
  markAsTroll
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
  initPrivateMessage
  sendPrivateMessage
  fetchFollowedChannels
  listParticipants
  addParticipants
  removeParticipants
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
  fetchActivityCount
  fetchGroupChannels
  followUser
  unfollowUser
  createGroupNotification
  getSiteMap
}
