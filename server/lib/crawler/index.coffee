{ isLoggedIn, error_404, error_500 } = require '../server/helpers'
{htmlEncode} = require 'htmlencode'
kodinghome = require './staticpages/kodinghome'
activity = require './staticpages/activity'
profile = require './staticpages/profile'
{Relationship} = require 'jraphical'

forceTwoDigits = (val) ->
  if val < 10
    return "0#{val}"
  return val

formatDate = (date) ->
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

decorateComment = (JAccount, comment, callback) ->
  createdAt = formatDate(new Date(comment.timestamp_))
  commentSummary = {body: comment.data.body, createdAt: createdAt}
  selector =
  {
    "targetId" : comment.getId(),
    "sourceName": "JAccount"
  }
  Relationship.one selector, (err, rel) =>
    if err
      console.error err
      callback null, err
    sel = { "_id" : rel.data.sourceId}

    JAccount.one sel, (err, acc) =>
      if err
        console.error err
        callback null, err
      commentSummary.authorName = acc.data.profile.firstName + " "
      commentSummary.authorName += acc.data.profile.lastName
      callback commentSummary, null

createActivityContent = (JAccount, models, comments, section, callback) ->
  model = models.first if models and Array.isArray models
  unless model
    callback null, "JStatusUpdate cannot be found."
  statusUpdateId = model.getId()
  jAccountId = model.data.originId
  selector =
  {
    "sourceId" : statusUpdateId,
    "as" : "author"
  }

  return callback "", null unless typeof model.fetchTeaser is "function"
  model.fetchTeaser (error, teaser)=>
    tags = []
    if teaser?.tags?
      tags = (tag.title for tag in teaser.tags)

    codeSnippet = ""
    if model.bongo_?.constructorName is "JCodeSnip"
      codeSnippet = model.data?.attachments[0]?.content

    Relationship.one selector, (err, rel) =>
      if err
          console.error err
          callback null, err
      sel =
      {
        "_id" : rel.data.targetId
      }
      JAccount.one sel, (err, acc) =>
        if err
          console.error err
          callback null, err

        fullName = "A koding user"
        if acc?.data?.profile?.firstName
          fullName = acc.data.profile.firstName + " "

        if acc?.data?.profile?.lastName
          fullName += acc.data.profile.lastName

        hash = ""
        if acc?.data?.profile?.hash
          hash = acc.data.profile.hash

        activityContent = {
          fullName : fullName
          hash : hash
          title : if model.title then model.title else model.body or ""
          body : if model.body  then model.body  else ""
          codeSnippet : htmlEncode codeSnippet
          createdAt : formatDate(model.data?.meta?.createdAt)
          numberOfComments : teaser.repliesCount or 0
          numberOfLikes : model?.data?.meta?.likes or 0
          comments : comments
          tags : tags
          type : model.bongo_?.constructorName
        }
        content = activity {activityContent, section, models}
        callback content, null

module.exports =
  crawl: (bongo, req, res, slug)->
    {Base, race, dash, daisy} = require "bongo"
    {JName, JAccount} = bongo.models
    {Relationship} = require 'jraphical'

    unless slug[0] is "/"
      slug = "/" + slug
    [slash, name, section] = slug.split("/")
    [firstLetter] = name

    # if there is no firstLetter, serve homepage to bot.
    unless firstLetter
      content = kodinghome()
      return res.send 200, content

    if firstLetter.toUpperCase() is firstLetter
      if section
        isLoggedIn req, res, (err, loggedIn, account)->
          # Serve homepage for Develop tab, instead of empty content.
          if name is "Develop"
            content = kodinghome()
            return res.send 200, content

          JName.fetchModels "#{name}/#{section}", (err, models)=>
            if err
              console.error err
              return res.send 500, error_500()
            model = models.first if models and Array.isArray models
            return res.send 404, error_404() unless model


            if typeof model.fetchRelativeComments is "function"
              model?.fetchRelativeComments? limit:3, after:"", (error, comments)=>
                queue = [0..comments.length].map (index)=>=>
                  comment = comments[index]
                  if comment?.data
                    # Get comments authors, put comment info into commentSummaries
                    decorateComment JAccount, comment, (commentSummary, error)=>
                      queue.next() if error
                      queue.commentSummaries or= []
                      if commentSummary.body
                        queue.commentSummaries.push commentSummary
                      queue.next()
                  else queue.next()
                queue.push =>
                  createActivityContent JAccount, models, \
                    queue.commentSummaries, section, (content, error)=>
                      queue.next() if error
                      return res.send 200, content
                daisy queue
            else
              createActivityContent JAccount, models, \
                {}, section, (content, error)=>
                  queue.next() if error
                  return res.send 200, content
      else
        return res.send 404, error_404("No section is given.")
    else
      isLoggedIn req, res, (err, loggedIn, account)->
        JName.fetchModels name, (err, models, jname)->
          return res.send 500, error_500()  if err
          return res.send 404, error_404()  if not models
          # this is a group, we are not serving groups to bots anymore.
          if jname.slugs.first.usedAsPath is "slug"
            return res.send 404, error_404()

          # this is a user
          else
            models.last.fetchOwnAccount (err, account)->
              content = profile {account}
              return res.send 200, content

