Algolia = require 'algoliasearch'
Promise = require 'bluebird'
globals = require 'globals'
kd = require 'kd'
KDNotificationView = kd.NotificationView
KDObject = kd.Object
remote = require('./remote').getInstance()

module.exports = class SearchController extends KDObject

  constructor: (options, data) ->

    super options, data

    @indexes = {}

    @initAlgolia()


  initAlgolia: ->

    { appId } = globals.config.algolia

    @ready = no

    @fetchApiKey (err, apiKey) =>

      return kd.error err  if err

      @fetchGroupId (err, currentGroupId) =>

        return console.error "Could not fetch current group id: #{err}"  if err

        @algolia = new Algolia appId, apiKey
        @algolia.setSecurityTags(createSecurityTag(currentGroupId))
        @ready = yes


  createSecurityTag = (currentGroupId) ->
    userId = globals.userAccount.socialApiId
    return "(#{currentGroupId},user-#{userId})"


  fetchGroupId: (callback) ->

    currentGroupId = globals.currentGroup.socialApiChannelId

    # TODO in case of an error this currentGroup.socialApiChannelId is not set.
    # this is just a workaround, and if possible solve this issue and remove these lines
    return callback null, currentGroupId  if currentGroupId

    remote.api.JGroup.one {slug: globals.currentGroup.slug}, (err, group) ->

      return callback err  if err

      return callback null, group.socialApiChannelId  if group?.socialApiChannelId

      return callback {message: "socialApiChannelId not found"}


  fetchApiKey: (callback) ->
    bo = backoff.exponential
      initialDelay: 700
      maxDelay    : 15000

    @indexes = {}
    @algolia = new Algolia appId, apiKey


  search: (indexName, seed, options) ->

    new Promise (resolve, reject) =>

      return reject new Error 'Illegal input'  if seed is ''

      index = @getIndex "#{ indexName }#{ globals.config.algolia.indexSuffix }"
      index.search seed, (success, results) ->

        return reject new Error "Couldn't search algolia"  unless success
        return resolve results.hits ? []

      , options


  searchAccountsMongo: (seed) ->
    val = seed.replace /^@/, ''

    query =
      'profile.nickname': val

    remote.api.JAccount.one query
      .then (it) -> [it]

  searchAccounts: (seed) ->

    seed = seed.replace /[^-\w]/g, ''

    @search 'accounts', seed, hitsPerPage : 10
      .then (data) ->
        throw new Error "No data!" if data.length is 0
        return data
      .map ({ objectID }) -> remote.cacheableAsync 'JAccount', objectID
      .catch (err) =>
        console.warn 'algolia strategy failed; trying mongo'
        console.warn err

        return @searchAccountsMongo seed
      .filter Boolean

  searchTopics: (seed) ->
    @search 'topics', seed

  searchChannel: (seed, channelId, options = {}) ->
    options.tagFilters = (options.tagFilters ? []).concat channelId

    @search 'messages', seed, options
      .map ({ objectID: id }) ->
        new Promise (resolve) ->
          kd.singletons.socialapi.message.byId { id }, (err, message) ->
            if err
              # NOTE: intentionally not rejecting here:
              console.warn "social api error:", err
            resolve message
      .filter Boolean
      .catch (e) ->
        new KDNotificationView title: "Search error!"

  getIndex: (indexName) ->
    unless @indexes[indexName]?
      index = @algolia.initIndex indexName
      # index.setSettings attributesForFaceting: 'channel'
      @indexes[indexName] = index
    @indexes[indexName]


