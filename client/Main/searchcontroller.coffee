class SearchController extends KDObject

  constructor: (options, data) ->

    super options, data

    { appId, apiKey } = KD.config.algolia

    @indexes = {}
    @algolia = new AlgoliaSearch appId, apiKey


  search: (indexName, seed, options) ->

    new Promise (resolve, reject) =>
      index = @getIndex "#{ indexName }#{ KD.config.algolia.indexSuffix }"
      index.search seed, (success, results) ->

        return reject new Error "Couldn't search algolia"  unless success
        return resolve results.hits ? []

      , options


  searchAccountsMongo: (seed) ->
    val = seed.replace /^@/, ''

    query =
      'profile.nickname': val

    KD.remote.api.JAccount.one query
      .then (it) -> [it]

  searchAccounts: (seed) ->
    @search 'accounts', seed
      .then (data) ->
        throw new Error "No data!" if data.length is 0
        return data
      .map ({ objectID }) -> KD.remote.cacheableAsync 'JAccount', objectID
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
          KD.singletons.socialapi.message.byId { id }, (err, message) ->
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
