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
  crawl: (bongo, {req, res, slug, isProfile}) ->
    {query} = req

    {Base, race, dash, daisy} = require "bongo"

    [name, section, entrySlug] = slug.split("/")

    handleError = (err, content) ->
      if err
        console.error err
        return res.send 404, error_404()  if err.error is 'koding.NotFoundError'
        return res.send 500, error_500()
      unless content
        console.error "not found"
        return res.send 404, error_404()

    {models} = bongo
    {generateFakeClient}   = require "../server/client"
    generateFakeClient req, res, (err, client) ->
      return handleError err  if err or not client

      page = getPage query
      options = {section, entrySlug, client, page, isProfile, name}
      fetchContent models, options, (err, content) ->
        return handleError err  if err or not content
        return res.send 200, content
