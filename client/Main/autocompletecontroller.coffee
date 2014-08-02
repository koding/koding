class AutoCompleteController extends KDObject

  constructor: (options, data) ->
    super options, data

    { appId, apiKey } = KD.config.algolia

    @indexes = {}
    @algolia = new AlgoliaSearch appId, apiKey

  search: (indexName, seed) ->
    new Promise (resolve) =>
      index = @getIndex "#{ indexName }#{ KD.config.algolia.indexSuffix }"
      index.search seed, (success, results) ->
        resolve if success then results.hits else []

  searchAccounts: (seed) ->
    @search 'accounts', seed
      .map (it) -> KD.remote.cacheableAsync 'JAccount', it.mongoId
      .filter Boolean

  getIndex: (indexName) ->
    @indexes[indexName] ?= @algolia.initIndex indexName
