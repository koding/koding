class AlgoliaResult

  constructor: (source) ->
    @[prop] = val  for own prop, val of source

  getId: -> @objectID
