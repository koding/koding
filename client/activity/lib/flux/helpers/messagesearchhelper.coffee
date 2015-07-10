prepareQueryForStore = (query) ->

  return (query ? '').toLowerCase()


getResultsFromStore = (store, query, channelId) ->

  return  unless store

  query = prepareQueryForStore query
  return store.getIn [ channelId, query ]


module.exports = {
  prepareQueryForStore
  getResultsFromStore
}