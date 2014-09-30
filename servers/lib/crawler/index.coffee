{ error_404, error_500 } = require '../server/helpers'
{htmlEncode}             = require 'htmlencode'
kodinghome               = require './staticpages/kodinghome'
activity                 = require './staticpages/activity'
feed                     = require './staticpages/feed'
profile                  = require './staticpages/profile'
{argv}                   = require 'optimist'
{uri}                    = require('koding-config-manager').load("main.#{argv.c}")
{createActivityContent}  = require './helpers'

notFoundError = (name) ->
  {description: "invalid #{name}", error: 'koding.NotFoundError'}


fetchProfileContent = (models, options, callback) ->
  {client, name} = options
  {JAccount, SocialChannel} = models
  JAccount.one "profile.nickname": name, (err, account) ->
    return callback err  if err or not account

    fetchOptions =
      targetId   : account.socialApiId
      limit      : 5
      replyLimit : 25

    SocialChannel.fetchProfileFeed client, fetchOptions, (err, result) ->
      return callback err  if err or not result
      unless result.length
        return callback null, profile account, ""

      feed.buildContent models, result, options, (err, content) ->
        return callback err  if err or not content
        callback null, profile account, content


fetchPostContent = (models, options, callback) ->
  {SocialMessage} = models
  {client, entrySlug} = options
  SocialMessage.bySlug client, slug: entrySlug, replyLimit: 25, (err, activity) ->
    return callback err  if err or not activity

    createActivityContent models, activity, (err, content, activityContent)->
      return callback err  if err or not content
      graphMeta =
        title    : "Post on koding.com by #{activityContent.fullName}"
        body     : "#{activityContent.body}"
        shareUrl : "#{uri.address}/Activity/Post/#{activityContent.slug}"
      fullPage = feed.putContentIntoFullPage content, "", graphMeta
      callback null, fullPage


fetchTopicContent = (models, options, callback) ->
  {client, entrySlug} = options

  options.channelName = entrySlug

  {SocialChannel} = models
  SocialChannel.byName client, name: entrySlug, (err, channel) ->
    return callback err  if err or not channel

    options.channelId = channel.channel.id
    options.route = "Topic/#{entrySlug}"
    options.contentType = "topic"
    feed.createFeed models, options, callback


fetchGroupContent = (models, options, callback) ->
  {entrySlug, client, page} = options
  entrySlug ||= "koding"
  {JGroup} = models

  options.channelName = "public"

  # TODO change this slug after groups are implemented
  JGroup.one slug: "koding", (err, group) ->
    return callback err  if err
    return callback notFoundError "group"  unless group

    options.channelId = group.socialApiChannelId
    # TODO change this with group implementation
    options.route = "Public"
    options.contentType = "post"
    feed.createFeed models, options, callback


fetchAnnouncementContent = (models, options, callback) ->

  {JGroup} = models

  options.channelName = "koding"

  # TODO change this slug after groups are implemented
  JGroup.one slug: "koding", (err, group) ->
    return callback err  if err
    return callback notFoundError "group"  unless group

    options.channelId = group.socialApiAnnouncementChannelId
    options.route = "Announcement"
    options.contentType = "post"
    feed.createFeed models, options, callback


fetchContent = (models, options, callback) ->
  {section, entrySlug, client} = options

  switch section
    when "Announcement"
      fetchAnnouncementContent models, options, callback
    when "Public"
      fetchGroupContent models, options, callback
    when "Topic"
      fetchTopicContent models, options, callback
    when "Post"
      fetchPostContent models, options, callback
    else
      return fetchProfileContent models, options, callback  if options.isProfile
      return callback notFoundError "section"


getPage = (query) ->
  {page}  = query
  page = parseInt( page, 10 );
  page   or= 1


module.exports =
  crawl: (bongo, {req, res, slug, isProfile}) ->
    {Base, race, dash, daisy} = require "bongo"

    [name, section, entrySlug] = slug.split("/")

    handleError = (err, content) ->
      if err
        console.error err
        return res.status(404).send error_404()  if err.error is 'koding.NotFoundError'
        return res.status(500).send error_500()
      unless content
        console.error "not found"
        return res.status(404).send error_404()

    {models} = bongo
    {generateFakeClient}   = require "../server/client"
    generateFakeClient req, res, (err, client) ->
      return handleError err  if err or not client

      {query} = req
      page = getPage query
      options = {section, entrySlug, client, page, isProfile, name}
      fetchContent models, options, (err, content) ->
        return handleError err  if err or not content
        return res.status(200).send content
