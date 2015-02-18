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

    { appId, apiKey } = globals.config.algolia

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


