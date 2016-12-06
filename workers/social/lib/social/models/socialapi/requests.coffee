KONFIG = require 'koding-config-manager'

request         = require 'request'
_               = require 'underscore'
KodingError     = require '../../error'

socialProxyUrl  = '/api/social'
localDomain     = KONFIG.socialapi.customDomain.local

wrapCallback = (callback) ->
  (err, response, body) ->
    if err
      if err.code is 'ECONNREFUSED'
        return callback new KodingError 'Social API is currently under maintenance'
      return callback err

    if response.statusCode >= 300
      return callback body
    else
      return callback null, body

createAccount = ({ id, nickname }, callback) ->
  if not id or not nickname
    return callback new KodingError 'Request is not valid for creating account'
  url = "#{socialProxyUrl}/account"
  post url, { oldId: id, nick: nickname }, callback

updateAccount = (data, callback) ->
  { id, nick } = data
  if not id or not nick
    return callback new KodingError 'Request is not valid for updating account'
  url = "#{socialProxyUrl}/account/#{id}"
  post url, data , callback

createChannel = (data, callback) ->
  unless data.name or data.creatorId
    return callback new KodingError 'Request is not valid for creating channel'
  url = "#{socialProxyUrl}/channel"
  post url, data, callback

fetchChannelActivities = (data, callback) ->
  if not data.channelId or not data.accountId
    return callback new KodingError 'Request is not valid for fetching activities'
  url = "#{socialProxyUrl}/channel/#{data.channelId}/history"
  get url, data, callback

fetchActivityCount = (data, callback) ->
  if not data.channelId
    return callback new KodingError 'Request is not valid for fetching activity count'

  url = "#{socialProxyUrl}/channel/#{data.channelId}/history/count"
  get url, data, callback

fetchGroupChannels = (data, callback) ->
  if not data.groupName or not data.accountId
    return callback new KodingError 'Request is not valid for fetching channel'

  # topic fetch is crashing so we forced for a limit here
  data.limit = 15

  url = "#{socialProxyUrl}/channel"
  get url, data, callback

fetchMessage = (data, callback) ->
  if not data.id
    return callback new KodingError 'Message id is not set'

  url = "#{socialProxyUrl}/message/#{data.id}"
  get url, data, callback

postToChannel = (data, callback) ->
  if not data.channelId or not data.accountId or not data.body
    return callback new KodingError 'Request is not valid for posting message'

  url = "#{socialProxyUrl}/channel/#{data.channelId}/message"
  post url, data, callback

editMessage = (data, callback) ->
  if not data.body or not data.id
    return callback new KodingError 'Request is not valid for editing a message'

  url = "#{socialProxyUrl}/message/#{data.id}"
  post url, data, callback

deleteMessage = (data, callback) ->
  unless data.id
    return callback new KodingError 'Request is not valid for deleting message'
  url =  "#{socialProxyUrl}/message/#{data.id}"
  deleteReq url, data, callback

likeMessage = (data, callback) ->
  unless data.id
    return callback new KodingError 'Request is not valid for liking a message'

  url = "#{socialProxyUrl}/message/#{data.id}/interaction/like/add"
  delete data.id
  post url, data, callback

unlikeMessage = (data, callback) ->
  unless data.id
    return callback new KodingError 'Request is not valid for unliking a message'

  url = "#{socialProxyUrl}/message/#{data.id}/interaction/like/delete"
  delete data.id
  post url, data, callback

listLikers = (data, callback) ->
  unless data.id
    return callback new KodingError 'Request is not valid for listing actors'

  url = "#{socialProxyUrl}/message/#{data.id}/interaction/like"
  delete data.id
  get url, data, callback

addReply = (data, callback) ->
  if not data.accountId or not data.body or not data.messageId
    return callback new KodingError 'Request is not valid for adding a reply'

  url = "#{socialProxyUrl}/message/#{data.messageId}/reply"
  post url, data, callback

listReplies = (data, callback) ->
  unless data.messageId
    return callback new KodingError 'Request is not valid for adding a reply'

  url = "#{socialProxyUrl}/message/#{data.messageId}/reply"
  get url, data, callback

fetchPopularTopics = (data, callback) ->
  if not data.groupName or not data.type
    return callback new KodingError 'Request is not valid for listing popular topics'

  url = "#{socialProxyUrl}/popular/topics/#{data.type}"
  get url, data, callback

fetchPopularPosts = (data, callback) ->
  if not data.groupName or not data.channelName
    return callback new KodingError 'Request is not valid for listing popular topics'

  url = "#{socialProxyUrl}/popular/posts/#{data.channelName}?limit=10"
  get url, data, callback

fetchPinnedMessages = (data, callback) ->
  url = "#{socialProxyUrl}/activity/pin/list"
  get url, data, callback

pinMessage = (data, callback) ->
  if not data.accountId or not data.messageId or not data.groupName
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/activity/pin/add"
  post url, data, callback

unpinMessage = (data, callback) ->
  if not data.accountId or not data.messageId or not data.groupName
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/activity/pin/remove"
  post url, data, callback

glancePinnedPost = (data, callback) ->
  if not data.accountId or not data.messageId or not data.groupName
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/activity/pin/glance"
  post url, data, callback

glanceNotifications = (data, callback) ->
  if not data.accountId
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/notification/glance"
  post url, data, callback

listNotifications = (data, callback) ->
  if not data.accountId # or not data.groupName
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/notification/#{data.accountId}"
  get url, data, callback

listParticipants = (data, callback) ->
  return callback new KodingError 'Request is not valid'  unless data.channelId
  url = "#{socialProxyUrl}/channel/#{data.channelId}/participants"
  get url, data, callback

addParticipants = (data, callback) ->
  url = "#{socialProxyUrl}/channel/#{data.channelId}/participants/add"
  doChannelParticipantOperation data, url, callback

removeParticipants = (data, callback) ->
  url = "#{socialProxyUrl}/channel/#{data.channelId}/participants/remove"

  { channelId, accountId, sessionToken } = data
  # fetch channel details
  channelById { id: channelId, accountId, sessionToken }, (err, channel) ->
    return callback err if err?
    return callback { message: 'Channel not found' } unless channel?.channel

    doChannelParticipantOperation data, url, callback

acceptInvite = (data, callback) ->

  unless data.channelId or data.accountId
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/channel/#{data.channelId}/invitation/accept"

  post url, data, callback

rejectInvite = (data, callback) ->

  unless data.channelId or data.accountId
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/channel/#{data.channelId}/invitation/reject"

  post url, data, callback

doChannelParticipantOperation = (data, url, callback) ->
  return callback new KodingError 'Request is not valid'  unless data.channelId

  # if accountIds is not set and also accountId is not set
  # return error
  if not data.accountIds
    return callback new KodingError 'Request is not valid'  if not data.accountId
    data.accountIds = [data.accountId]

  { participantStatus: statusConstant } = data

  # make the object according to channel participant data
  req = ({ accountId, statusConstant } for accountId in data.accountIds)
  req.sessionToken = data.sessionToken
  url = "#{url}?accountId=#{data.accountId}"
  post url, req, callback

updateLastSeenTime = (data, callback) ->
  unless data.channelId and data.accountId
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/channel/#{data.channelId}/participant/#{data.accountId}/presence"
  post url, data, callback

fetchFollowedChannels = (data, callback) ->
  if not data.accountId or not data.groupName
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/account/#{data.accountId}/channels"
  get url, data, callback

fetchFollowedChannelCount = (data, callback) ->
  if not data.accountId or not data.groupName
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/account/#{data.accountId}/channels/count"
  get url, data, callback

createChannelWithParticipants = (data, callback) ->
  url = "#{socialProxyUrl}/channel/initwithparticipants"
  post url, data, callback

sendMessageToChannel = (data, callback) ->
  if not data.body or not data.channelId
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/channel/sendwithparticipants"
  post url, data, callback

initPrivateMessage = (data, callback) ->
  url = "#{socialProxyUrl}/privatechannel/init"
  post url, data, callback

sendPrivateMessage = (data, callback) ->
  if not data.body or not data.channelId
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/privatechannel/send"
  post url, data, callback

fetchPrivateMessages = (data, callback) ->
  url = "#{socialProxyUrl}/privatechannel/list"
  get url, data, callback

fetchPrivateMessageCount = (data, callback) ->
  url = "#{socialProxyUrl}/privatechannel/count"
  get url, data, callback

searchChats = (data, callback) ->
  if not data.name
    return callback new KodingError 'Name should be set for chat search'
  url = "#{socialProxyUrl}/privatechannel/search"
  get url, data, callback

followUser = (data, callback) ->
  followHelper data, addParticipants, callback

unfollowUser = (data, callback) ->
  followHelper data, removeParticipants, callback

followHelper = (data, followFn, callback) ->
  unless data.accountId and data.creatorId
    return callback new KodingError 'Request is not valid'

  data.typeConstant = 'followers'
  data.name = "FollowersChannelAccount-#{data.creatorId}"

  createChannel data, (err, socialApiChannel) ->
    return callback err  if err
    data.channelId = socialApiChannel.id
    followFn data, callback

createGroupNotification = (data, callback) ->
  unless data.admins?.length and data.actorId and data.name
    return callback new KodingError 'Request is not valid'

  url = "#{socialProxyUrl}/notification/group"
  post url, data, callback

searchTopics = (data, callback) ->
  if not data.name
    return callback new KodingError 'Name should be set for topic search'
  url = "#{socialProxyUrl}/channel/search"
  get url, data, callback

fetchProfileFeed = (data, callback) ->
  if not data.targetId
    return callback new KodingError 'targetId should be set'
  url = "#{socialProxyUrl}/account/#{data.targetId}/posts"
  get url, data, callback

fetchProfileFeedCount = (data, callback) ->
  if not data.targetId
    return callback new KodingError 'targetId should be set'
  url = "#{socialProxyUrl}/account/#{data.targetId}/posts/count"
  get url, data, callback

messageById = (data, callback) ->
  if not data.id
    return callback new KodingError 'id should be set'
  url = "#{socialProxyUrl}/message/#{data.id}"
  get url, data, callback

messageBySlug = (data, callback) ->
  if not data.slug
    return callback new KodingError 'slug should be set'
  url = "#{socialProxyUrl}/message/slug/#{data.slug}"
  get url, data, callback

channelById = (data, callback) ->
  if not data.id
    return callback new KodingError 'id should be set'
  url = "#{socialProxyUrl}/channel/#{data.id}"
  get url, data, callback

channelByName = (data, callback) ->
  if not data.name
    return callback new KodingError 'name should be set'
  url = "#{socialProxyUrl}/channel/name/#{data.name}"
  get url, data, callback

checkChannelParticipation = (data, callback) ->
  if not data.name or not data.type
    return callback new KodingError 'request is not valid'

  url = "#{socialProxyUrl}/channel/checkparticipation"
  get url, data, callback

getSiteMap = (data, callback) ->
  url = data.name
  getXml url, {}, callback

updateChannel = (data, callback) ->
  url = "#{socialProxyUrl}/channel/#{data.id}/update"
  post url, data, callback

createChannel = (data, callback) ->
  url = "#{socialProxyUrl}/channel"
  post url, data, callback

deleteChannel = (data, callback) ->
  url = "#{socialProxyUrl}/channel/#{data.channelId}/delete"
  post url, data, callback

checkOwnership = (data, callback) ->
  url = "#{socialProxyUrl}/account/#{data.accountId}/owns"
  get url, data, callback

createNotificationSetting = (data, callback) ->
  url = "#{socialProxyUrl}/channel/#{data.channelId}/notificationsetting"
  post url, data, callback

getNotificationSetting = (data, callback) ->
  url = "#{socialProxyUrl}/channel/#{data.channelId}/notificationsetting"
  get url, data, callback

updateNotificationSetting = (data, callback) ->
  url = "#{socialProxyUrl}/notificationsetting/#{data.id}"
  post url, data, callback

deleteNotificationSetting = (data, callback) ->
  url = "#{socialProxyUrl}/notificationsetting/#{data.id}"
  deleteReq url, data, callback

createCustomer = (data, callback) ->
  url = "#{socialProxyUrl}/payment/customer/create"
  post url, data, callback

createSubscription = (data, callback) ->
  url = "#{socialProxyUrl}/payment/subscription/create"
  post url, data, callback

hasCreditCard = (client, callback) ->

  { sessionToken } = client

  url = "#{socialProxyUrl}/payment/creditcard/has"
  get url, { sessionToken }, callback

expireSubscription = (accountId, callback) ->
  url = "#{socialProxyUrl}/payments/customers/#{accountId}/expire"
  post url, {}, callback

dispatchEvent = (eventName, data, callback) ->
  url = "#{socialProxyUrl}/private/dispatcher/#{eventName}"
  post url, data, callback

storeCredential = (data, callback) ->
  if not data.pathName
    return callback new KodingError 'Request is not valid for storing credential'

  pathName = data.pathName
  delete data.pathName

  url = "#{socialProxyUrl}/credential/#{pathName}"
  post url, data, callback

getCredential = (data, callback) ->
  if not data.pathName
    return callback new KodingError 'Request is not valid for getting credential'
  url = "#{socialProxyUrl}/credential/#{data.pathName}"
  get url, data, callback

deleteCredential = (data, callback) ->
  if not data.pathName
    return callback new KodingError 'Request is not valid for deleting credential'
  url = "#{socialProxyUrl}/credential/#{data.pathName}"
  deleteReq url, data, callback

publishMailEvent = (data, callback) ->
  url = "#{socialProxyUrl}/private/mail/publish"
  post url, data, callback

post = (url, data, callback) ->
  reqOptions =
    url    : "#{localDomain}#{url}"
    json   : true
    method : 'POST'

  { reqOptions, data } = setCookieIfRequired reqOptions, data
  { reqOptions, data } = setHeaderIfRequired reqOptions, data

  reqOptions.body = data

  request reqOptions, wrapCallback callback

deleteReq = (url, data, callback) ->
  [data, callback] = [null, data] unless callback

  reqOptions =
    url    : "#{localDomain}#{url}"
    json   : true
    method : 'DELETE'

  { reqOptions, data } = setCookieIfRequired reqOptions, data

  request reqOptions, wrapCallback callback

put = (url, data, callback) ->
  [data, callback] = [null, data]  unless callback

  reqOptions =
    url    : "#{localDomain}#{url}"
    json   : true
    method : 'PUT'

  { reqOptions, data } = setCookieIfRequired reqOptions, data
  { reqOptions, data } = setHeaderIfRequired reqOptions, data

  reqOptions.body = data

  request reqOptions, wrapCallback callback

getXml = (url, data, callback) ->
  reqOptions =
    url    : "#{localDomain}#{url}"
    method : 'GET'

  { reqOptions, data } = setCookieIfRequired reqOptions, data

  request reqOptions, wrapCallback callback

get = (url, data, callback) ->
  reqOptions =
    url    : "#{localDomain}#{url}"
    json   : true
    method : 'GET'

  { reqOptions, data } = setCookieIfRequired reqOptions, data

  # finally set query string
  reqOptions.qs = data

  request reqOptions, wrapCallback callback

setCookieIfRequired = (reqOptions, data) ->
  # inject clientId cookie if exists
  if data?.sessionToken
    j = request.jar()
    cookie = request.cookie "clientId=#{data.sessionToken}"
    j.setCookie cookie, reqOptions.url, {}, ->
    reqOptions.jar = j

    delete data.sessionToken

  return { reqOptions, data }

setHeaderIfRequired = (reqOptions, data) ->
  # inject clientId cookie if exists
  if data?.clientIP
    reqOptions.headers = {
      'X-Forwarded-For': data.clientIP
    }

    delete data.clientIP

  return { reqOptions, data }

module.exports = {
  messageBySlug
  checkChannelParticipation
  messageById
  channelById
  channelByName
  glancePinnedPost
  glanceNotifications
  listNotifications
  updateLastSeenTime
  fetchProfileFeed
  fetchProfileFeedCount
  searchTopics
  searchChats
  createChannelWithParticipants
  sendMessageToChannel
  fetchPrivateMessages
  fetchPrivateMessageCount
  initPrivateMessage
  sendPrivateMessage
  fetchFollowedChannels
  fetchFollowedChannelCount
  listParticipants
  addParticipants
  removeParticipants
  acceptInvite
  rejectInvite
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
  updateAccount
  createChannel
  fetchMessage
  fetchChannelActivities
  fetchActivityCount
  fetchGroupChannels
  followUser
  unfollowUser
  createGroupNotification
  getSiteMap
  deleteChannel
  updateChannel
  createChannel
  checkOwnership
  createNotificationSetting
  getNotificationSetting
  updateNotificationSetting
  deleteNotificationSetting
  createCustomer
  createSubscription
  hasCreditCard
  expireSubscription
  dispatchEvent
  storeCredential
  getCredential
  deleteCredential
  post
  get
  deleteReq
  put
  publishMailEvent
}
