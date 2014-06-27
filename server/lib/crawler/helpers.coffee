{argv}  = require 'optimist'
{uri}   = require('koding-config-manager').load("main.#{argv.c}")
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
          <a class="ttag expandable" href="#{uri.address}/Activity?tagged=#{title}">
            <span>#{tagTitle}</span>
          </a>
        </span>
      """
    return tagContent

createActivityContent = (JAccount, model, comments, createFullHTML=no, putBody=yes, callback) ->
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
        return callback err, null

      profile = getProfile acc
      slug    = teaser?.slug or "#"

      {meta:{createdAt}} = model  if model
      createdAt          = if createdAt then formatDate createdAt else ""

      # If href goes to outside of koding, add rel=nofollow.
      # this is necessary to prevent link abusers.
      renderer = new marked.Renderer()
      renderer.link= (href, title, text)->
        linkHTML = "<a href=\"#{href}\""
        if title
          linkHTML += " title=\"#{title}\""

        re = new RegExp("#{uri.address}", "g")
        if re.test href
          linkHTML += ">#{text}</a>"
        else
          linkHTML += " rel=\"nofollow\">#{text}</a>"
        return linkHTML

      if model?.body? and putBody
        body = marked model.body,
          renderer  : renderer
          gfm       : true
          pedantic  : false
          sanitize  : true
        body = normalizeActivityBody model, body
      else
        body = ""
      activityContent =
        slug             : teaser.slug
        fullName         : profile.fullName
        nickname         : profile.nickname
        hash             : profile.hash
        avatar           : profile.avatar
        title            : if model?.title then model.title else model.body or ""
        body             : body
        createdAt        : createdAt
        numberOfComments : teaser.repliesCount or 0
        numberOfLikes    : model?.meta?.likes or 0
        comments         : comments
        tags             : tags
        type             : model?.bongo_?.constructorName
      activityContent.title = encoder.XSSEncode activityContent.title
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

      profile = getProfile acc

      commentSummary.authorName     = profile.fullName
      commentSummary.authorNickname = profile.nickname
      commentSummary.authorHash     = profile.hash or ''
      commentSummary.authorAvatar   = profile.avatar

      callback null, commentSummary

module.exports = {
  getProfile
  getAvatarImageUrl
  forceTwoDigits
  formatDate
  createActivityContent
  decorateComment
}