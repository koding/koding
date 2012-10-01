jraphical = require 'jraphical'

module.exports = class JFeed extends jraphical.Module
  {secure} = require 'bongo'
  @share()

  @set
    schema          :
      title         :
        type        : String
        required    : yes
      description   : String
      owner         :
        type        : String
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
    feed = new JFeed {
      title
      description
      owner: account.profile.nickname
    }
    saveFeedToAccount feed, account, callback

  @assureFeed = (account, data, callback) ->
    {title, description} = data
    selectorOrInitializer =
      title: title
      description: description
      owner: account.profile.nickname
    @assure selectorOrInitializer, (err, feed) ->
      if err then callback err
      else saveFeedToAccount feed, account, callback

  fetchActivities: (callback) ->
    # {connection:{delegate}} = client
    # TODO: Only allow querying from own feed
    CActivity = require "./activity/index"
    {Relationship} = jraphical
    Relationship.all {sourceId: @getId(), as: "container"}, (err, rels) ->
    # @fetchContents (err, contents) ->
      ids = (rel.targetId for rel in rels)
      CActivity.all {_id: {$in: ids}}, callback



