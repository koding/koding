class AutoCompleteController extends KDObject

  constructor: (options, data) ->
    super options, data

    { appId, apiKey } = KD.config.algolia

    @indexes = {}
    @algolia = new AlgoliaSearch appId, apiKey

  search: (indexName, seed) ->
    new Promise (resolve, reject) =>
      index = @getIndex "#{ indexName }#{ KD.config.algolia.indexSuffix }"
      index.search seed, (success, results) ->
        return reject new Error "Couldn't search algolia"  unless success
        return resolve results.hits ? []

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
      .catch (err) => @searchAccountsMongo seed
      .filter Boolean

  searchTopics: (seed) ->
    @search 'topics', seed

  getIndex: (indexName) ->
    @indexes[indexName] ?= @algolia.initIndex indexName
