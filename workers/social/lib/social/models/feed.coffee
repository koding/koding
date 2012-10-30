jraphical = require 'jraphical'
{extend} = require 'underscore'
KodingError = require '../error'

module.exports = class JFeed extends jraphical.Module
  {secure, ObjectId} = require 'bongo'
  @share()

  @set
    schema          :
      title         :
        type        : String
        required    : yes
      description   : String
      owner         :
        type        : ObjectId
        required    : yes
      meta          : require 'bongo/bundles/meta'
    relationships   :
      content       :
        as          : 'container'
        targetType  : ["CActivity", "JStatusUpdate", "JCodeSnip", "JComment"]

    sharedMethods   :
      instance      : [
        'fetchContents', 'fetchActivities'
      ]

  saveFeedToAccount = (feed, account, callback) ->
    feed.save (err) ->
      if err then callback err
      else 
        account.addFeed feed, (err) ->
          if err then callback err
          else callback null, feed

  @createFeed = (account, options, callback) ->
    {title, description} = options
    description ?= ""
    feed = new JFeed {
      title
      description
      owner: account._id
    }
    saveFeedToAccount feed, account, callback

  @assureFeed = (account, data, callback) ->
    JAccount = require './account'
    return unless account instanceof JAccount
    {title, description} = data
    description ?= ""
    selectorOrInitializer =
      title: title
      description: description
      owner: account._id
    @assure selectorOrInitializer, (err, feed) ->
      if err then callback err
      else saveFeedToAccount feed, account, callback

  fetchActivities: secure (client, selector, options, callback) ->
    [callback, options] = [options, callback] unless callback
    options or= {}

    {connection:{delegate}} = client
    unless delegate._id.toString() is @owner.toString()
      callback new KodingError 'Access denined.'
    else
      CActivity = require "./activity/index"
      {Relationship} = jraphical

      Relationship.all {sourceId: @getId(), as: "container"}, (err, rels) ->
      # @fetchContents (err, contents) ->
        if err
          callback()
        else
          ids = (rel.targetId for rel in rels)
          selector = extend selector, {_id: {$in: ids}}
          CActivity.someData selector, {snapshot: true}, options, (err, cursor) ->
            cursor.toArray callback
