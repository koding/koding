{ isLoggedIn, error_404, error_500 } = require '../server/helpers'
{htmlEncode}                         = require 'htmlencode'
kodinghome                           = require './staticpages/kodinghome'
activity                             = require './staticpages/activity'
crawlableFeed                        = require './staticpages/feed'
profile                              = require './staticpages/profile'
{Relationship}                       = require 'jraphical'

{
  forceTwoDigits
  formatDate
  getFullName
  getNickname
  getUserHash
  createActivityContent
  decorateComment
}          = require './helpers'

fetchLastStatusUpdatesOfUser = (account, Relationship, JNewStatusUpdate, callback) ->
  {daisy} = require "bongo"
  return callback null, null  unless account?._id
  originId = account._id

  feedOptions  =
    sort       : 'timestamp' : -1
    limit      : 20

  selector     =
    targetId   : originId
    targetName : "JAccount"
    sourceName : "JNewStatusUpdate"
    as         : "author"
    data       :          # we should filter by group because when the group is
      group    : "koding" # private publishing on profile page will cause data leak ~EA

  Relationship.some selector, feedOptions, (err, relationships)->
    return callback err, null  if err
    return callback null, null  unless relationships?.length > 0
    queue = [0..relationships.length - 1].map (index)=>=>
      rel = relationships[index]
      queue.next  unless rel?.sourceId?
      sel =
        _id        : rel.sourceId
        originType : "JAccount"
      JNewStatusUpdate.one sel, {}, (error, statusUpdate)=>
        queue.next()  if error
        queue.next()  unless statusUpdate
        queue.statusUpdates or= []
        queue.statusUpdates.push statusUpdate
        queue.next()
    queue.push =>
      return callback null, queue.statusUpdates
    daisy queue

isInAppRoute = (firstLetter)->
  # user nicknames can start with numbers
  intRegex = /^\d/
  return false if intRegex.test firstLetter
  return true  if firstLetter.toUpperCase() is firstLetter
  return false

module.exports =
  crawl: (bongo, req, res, slug)->
    {query} = req
    {page}  = query
    page = parseInt( page, 10 );
    page   or= 1
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

    if isInAppRoute firstLetter
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

            model = models.first  if models and Array.isArray models
            return res.send 404, error_404()  unless model

            if typeof model.fetchRelativeComments is "function"
              model?.fetchRelativeComments? limit:3, after:"", (error, comments)=>
                queue = [0..comments.length].map (index)=>=>
                  comment = comments[index]
                  if comment?
                    # Get comments authors, put comment info into commentSummaries
                    decorateComment JAccount, comment, (error, commentSummary)=>
                      queue.next()  if error
                      queue.commentSummaries or= []
                      if commentSummary?.body?
                        queue.commentSummaries.push commentSummary
                      queue.next()
                  else queue.next()
                queue.push =>
                  createFullHTML = yes
                  putBody = yes
                  createActivityContent JAccount, model, queue.commentSummaries, createFullHTML, putBody, (error, content)=>
                    return res.send 500, error_500()  if error
                    return res.send 200, content
                daisy queue
            else
              createFullHTML = no
              putBody = yes
              createActivityContent JAccount, model, {}, createFullHTML, putBody, (error, content)=>
                return res.send 500, error_500()  if error
                return res.send 200, content
      else
        if /^(Activity)|(Topics)/.test name

          crawlableFeed bongo, page, name, (error, content)->
            return res.send 500, error_500()  if error
            return res.send 404, error_404()  unless content
            return res.send 200, content
        else
          return res.send 404, error_404("No section is given.")
    else
      isLoggedIn req, res, (err, loggedIn, account)->
        JName.fetchModels name, (err, models, jname)->
          return res.send 500, error_500()  if err
          return res.send 404, error_404()  if not models?.last?
          # this is a group, we are not serving groups to bots anymore.
          if jname.slugs.first.usedAsPath is "slug"
            return res.send 404, error_404()

          # this is a user
          else
            models.last.fetchOwnAccount (err, account)->
              {JNewStatusUpdate} = bongo.models
              fetchLastStatusUpdatesOfUser account, Relationship, JNewStatusUpdate, (error, statusUpdates = []) =>
                return res.send 500, error_500()  if error
                queue = [0..statusUpdates.length].map (index)=>=>
                  queue.decoratedStatusUpdates or= []
                  statusUpdate = statusUpdates[index]
                  if statusUpdate?
                    statusUpdate.fetchTeaser (err, teaser)=>
                      return queue.next()  if err
                      return queue.next()  unless teaser
                      unless teaser?.replies
                        queue.decoratedStatusUpdates.push teaser
                        return queue.next()
                      originIds = teaser.replies.map (teaser)->
                        teaser.originId
                      JAccount.some {_id:$in:originIds}, {}, (err, accounts)=>
                        return queue.next()  if err
                        return queue.next()  unless accounts
                        for acc in accounts
                          for comment in teaser.replies
                            if comment.originId.toString() is acc._id.toString()
                              comment.author = acc.data.profile
                        queue.decoratedStatusUpdates.push teaser
                        queue.next()
                  else queue.next()
                queue.push =>
                  content = profile account, queue.decoratedStatusUpdates
                  return res.send 200, content
                daisy queue


