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
      .map ({ objectID }) -> KD.remote.cacheableAsync 'JAccount', objectID
      .filter Boolean

  getIndex: (indexName) ->
    @indexes[indexName] ?= @algolia.initIndex indexName
