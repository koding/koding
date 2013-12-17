{ isLoggedIn, error_404, error_500 } = require '../server/helpers'
{htmlEncode} = require 'htmlencode'
kodinghome = require './staticpages/kodinghome'
activity = require './staticpages/activity'
crawlableFeed = require './staticpages/feed'
profile = require './staticpages/profile'
{Relationship} = require 'jraphical'

{
  forceTwoDigits
  formatDate
  getFullName
  getNickname
  getUserHash
  createActivityContent
  decorateComment
}          = require './helpers'

fetchLastStatusUpdatesOfUser = (account, Relationship, JStatusUpdate, callback) ->
  {daisy} = require "bongo"
  originId = account._id
  selector =
    "targetId"   : originId
    "targetName" : "JAccount"
    "sourceName" : "JStatusUpdate"
    "as"         : "author"

  Relationship.some selector, limit: 3, (err, relationships)->
    return callback err, null if err
    return callback null, null unless relationships?.length > 0
    queue = [0..relationships.length - 1].map (index)=>=>
      rel = relationships[index]
      queue.next unless rel?.sourceId?
      sel =
        _id        : rel.sourceId
        originType : "JAccount"
      JStatusUpdate.one sel, {}, (error, statusUpdate)=>
        queue.next() if error
        queue.next() unless statusUpdate
        queue.statusUpdates or= []
        queue.statusUpdates.push statusUpdate
        queue.next()
    queue.push =>
      return callback null, queue.statusUpdates
    daisy queue

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
                  if comment?
                    # Get comments authors, put comment info into commentSummaries
                    decorateComment JAccount, comment, (error, commentSummary)=>
                      queue.next() if error
                      queue.commentSummaries or= []
                      if commentSummary.body
                        queue.commentSummaries.push commentSummary
                      queue.next()
                  else queue.next()
                queue.push =>
                  createActivityContent JAccount, model, queue.commentSummaries, yes, (error, content)=>
                    queue.next() if error
                    return res.send 200, content
                daisy queue
            else
              createActivityContent JAccount, model, {}, yes, (error, content)=>
                return res.send 200, content
      else
        if /^(Activity)|(Topics)/.test name
          if /\?page=/.test name
            parts = name.split "?"
            if parts[0] in ["Activity", "Topics"]
              name = parts[0]
            else
              return res.send 404, error_404()
            if parts[1]
              querystringParams = parts[1].split "&"
              for param in querystringParams
                if /page=/.test param
                  [key, value] = param.split "="
                  page = parseInt(value) ? 1  if value
            else
              return res.send 500, error_500()

          if isNaN page
            page = 1

          crawlableFeed bongo, page, name, (error, content)->
            return res.send 500, error_500() if error or not content
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
              {JStatusUpdate} = bongo.models
              # TODO user's other activity types must be shown, such as blogposts, code snippets etc.
              fetchLastStatusUpdatesOfUser account, Relationship, JStatusUpdate, (error, statusUpdates) =>
                return res.send 500, error_500()  if error
                content = profile {account, statusUpdates}
                return res.send 200, content

