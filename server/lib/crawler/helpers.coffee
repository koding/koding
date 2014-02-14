{argv} = require 'optimist'
{uri} = require('koding-config-manager').load("main.#{argv.c}")

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

getFullName = (account) ->
  fullName = "A koding user"
  if account?.data?.profile?.firstName?
    fullName = account.data.profile.firstName + " "

  if account?.data?.profile?.lastName?
    fullName += account.data.profile.lastName
  return fullName

getNickname = (account) ->
  nickname = "A koding user"
  if account?.data?.profile?.nickname?
    nickname = account.data.profile.nickname
  return nickname

getUserHash = (account) ->
  hash = ""
  if account?.data?.profile?.hash?
    hash = account.data.profile.hash
  return hash

normalizeActivityBody = (activity, bodyString="") ->
  if bodyString
    body = bodyString
  else
    {body} = activity

  tagMap = {}
  activity.tags?.forEach (tag) -> tagMap[tag.getId()] = tag

  return body.replace /\|(.+?)\|/g, (match, tokenString) ->
    [prefix, constructorName, id, title] = tokenString.split /:/

    switch prefix
      when "#" then token = tagMap?[id]

    tagTitle = if token then token.title else title

    return ""  unless tagTitle
    tagContent =
      """
        <span class="kdview token">
          <a class="ttag expandable" href="#{uri.address}/#!/Activity?tagged=#{title}">
            <span>#{tagTitle}</span>
          </a>
        </span>
      """
    return tagContent

createActivityContent = (JAccount, model, comments, createFullHTML=no, putBody=yes, callback) ->
  # console.log "model", model
  {Relationship} = require 'jraphical'
  {htmlEncode}   = require 'htmlencode'
  marked         = require 'marked'
  {getSingleActivityPage, getSingleActivityContent} = require './staticpages/activity'

  statusUpdateId = model.getId()
  jAccountId = model.originId
  selector =
    "sourceId" : statusUpdateId,
    "as"       : "author"

  return callback new Error "Cannot call fetchTeaser function.", null unless typeof model.fetchTeaser is "function"
  model.fetchTeaser (error, teaser)=>
    tags = []
    tags = teaser.tags  if teaser?.tags?

    sel =
      "_id" : model.originId

    JAccount.one sel, (err, acc) =>
      if err
        console.error err
        callback err, null

      # No need to return if acc is not found.
      # Write default values instead.
      fullName = getFullName acc
      nickname = getNickname acc
      hash     = getUserHash acc
      slug     = teaser?.slug or "#"

      if model?.body? and putBody
        body = marked model.body,
          gfm       : true
          pedantic  : false
          sanitize  : true
        body = normalizeActivityBody model, body
      else
        body = ""

      activityContent =
        slug             : teaser.slug
        fullName         : fullName
        nickname         : nickname
        hash             : hash
        title            :  if model?.title? then model.title else model.body or ""
        body             : body
        createdAt        : if model?.meta?.createdAt? then formatDate model.meta.createdAt else ""
        numberOfComments : teaser.repliesCount or 0
        numberOfLikes    : model?.meta?.likes or 0
        comments         : comments
        tags             : tags
        type             : model?.bongo_?.constructorName

      if createFullHTML
        content = getSingleActivityPage {activityContent, model}
      else
        content = getSingleActivityContent activityContent, model
      return callback null, content

decorateComment = (JAccount, comment, callback) ->
  { Relationship } = require 'jraphical'
  createdAt = formatDate(new Date(comment.timestamp_))
  commentSummary = {body: comment.body, createdAt: createdAt}
  selector =
  {
    "targetId" : comment.getId(),
    "sourceName": "JAccount"
  }
  Relationship.one selector, (err, rel) =>
    if err
      console.error err
      callback err, null
    return callback err, null  unless rel?.sourceId?
    sel = { "_id" : rel.sourceId}

    JAccount.one sel, (err, acc) =>
      if err
        console.error err
        callback err, null
      commentSummary.authorName     = getFullName acc
      commentSummary.authorNickname = getNickname acc
      if acc?.data?.profile?.hash
        commentSummary.authorHash   = acc.data.profile.hash
      commentSummary.authorHash   or= ""
      callback null, commentSummary

module.exports = {
  forceTwoDigits
  formatDate
  getFullName
  getNickname
  getUserHash
  createActivityContent
  decorateComment
}