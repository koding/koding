{argv}  = require 'optimist'
{uri}   = require('koding-config-manager').load("main.#{argv.c}")
{daisy} = require('bongo')
encoder = require 'htmlencode'

getProfile = (account) ->
  {profile:{nickname, firstName, lastName, about, hash, avatar}} = account if account
  fullName = firstName + " " + lastName ? (firstName and lastName)

  unless fullName
    fullName = firstName ? lastName ? nickname

  # if firstname and lastname is empty, assign nickname to firstname.
  # it is used in profile.coffee
  unless firstName or lastName
    firstName = nickname

  # if a fullName still can't be found, write a default name.
  unless fullName
    fullName = "A koding user"

  userProfile =
    nickname    : encoder.XSSEncode nickname ? "A koding nickname"
    firstName   : encoder.XSSEncode firstName
    lastName    : encoder.XSSEncode lastName
    about       : encoder.XSSEncode about ? ""
    hash        : hash or ''
    avatar      : avatar or no
    fullName    : encoder.XSSEncode fullName

  return userProfile

forceTwoDigits = (val) ->
  if val < 10
    return "0#{val}"
  return val

formatDate = (date) ->
  return ""  unless date
  year = date.getFullYear()
  month = date.getMonth()
  day = forceTwoDigits date.getDate()
  hour = forceTwoDigits date.getHours()
  minute = forceTwoDigits date.getMinutes()

  # What about i18n? Does GoogleBot crawl in different languages?
  months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  monthName = months[month]
  return "#{monthName} #{day}, #{year} #{hour}:#{minute}"

createProfile = (models, activity, callback)->
  {JAccount} = models
  {accountOldId} = activity
  JAccount.one "_id" : accountOldId, (err, acc) =>
    return callback err  if err
    return callback message: "account not found"  unless acc

    renderedProfile = getProfile acc
    callback null, renderedProfile

renderCreatedAt = (activity) ->
  {message:{createdAt}} = activity  if activity
  return formatDate new Date(createdAt)

prepareComments = (models, activity, callback) ->
  {JAccount} = models
  {replies} = activity
  return callback null  unless replies.length

  queue = []
  queue = replies.map (reply) ->->
    JAccount.one _id: reply.accountOldId, (err, account) ->
      if err
        console.error "Could not fetch replier information #{reply.accountOldId}"
        return queue.next()

      reply.replier   = getProfile account
      {formatBody} = require './staticpages/bodyrenderer'
      reply.message.body = formatBody reply.message.body
      reply.message.createdAt = renderCreatedAt reply
      queue.next()

  queue.push ->
    callback null, replies

  daisy queue

prepareLikes = (models, activity, callback) ->
  {JAccount} = models

  like = activity?.interactions?.like
  return callback null  unless like?.actorsPreview?.length

  queue = []
  actors = []
  queue = like.actorsPreview.map (actor)->->
    JAccount.one _id: actor, (err, account) ->
      if err
        console.error "Could not fetch interactor information #{actor}"
        return queue.next()

      actors.push getProfile account

      queue.next()

  queue.push ->
    callback null, actors

  daisy queue


prepareActivity = (models, {activity, profile}, callback) ->
  {message, repliesCount, interactions} = activity
  {slug, body, createdAt} = message
  {like:{actorsCount}} = interactions

  activityContent =
    slug             : slug or "#"
    fullName         : profile.fullName
    nickname         : profile.nickname
    hash             : profile.hash
    avatar           : profile.avatar
    body             : body
    createdAt        : renderCreatedAt activity
    commentCount     : repliesCount
    likeCount        : actorsCount

  queue = [
    ->
      prepareComments models, activity, (err, replies) ->
        return callback err  if err
        activityContent.replies = replies  if replies
        queue.next()
    ,
    ->
      prepareLikes models, activity, (err, likers) ->
        return callback err  if err
        activityContent.likers = likers  if likers
        queue.next()
    ,
    ->
      callback null, activityContent
    ]

  daisy queue

createActivityContent = (models, activity, callback) ->
  {htmlEncode}   = require 'htmlencode'
  {getActivityContent} = require './staticpages/activity'

  createProfile models, activity, (err, profile) ->
    return callback err, null  if err

    prepareActivity models, {activity, profile}, (err, activityContent) ->
      return callback err  if err
      content = getActivityContent activityContent
      result = {activityContent, profile}
      return callback null, content, activityContent

module.exports = {
  getProfile
  createActivityContent
}
