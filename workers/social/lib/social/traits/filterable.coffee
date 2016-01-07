module.exports = class Filterable
  { secure, ObjectId } = require 'bongo'
  { permit } = require '../models/group/permissionset'

  @findSuggestions = ->
    throw new Error 'Filterable must implement static method findSuggestions!'

  @byRelevance = (client, seed, options, callback) ->
    [callback, options] = [options, callback] unless callback
    { limit, blacklist, skip }  = options
    limit     ?= 10
    blacklist or= []
    blacklist = blacklist.map(ObjectId)
    cleanSeed = seed.replace(/[^\w\s-]/).trim().replace(/(\W)/g, '\\$1') #TODO: this is wrong for international charsets
    startsWithSeedTest = RegExp '^'+cleanSeed, 'i'
    startsWithOptions = { limit, blacklist, skip }
    @findSuggestions client, startsWithSeedTest, startsWithOptions, (err, suggestions) =>
      if err
        callback err
      else if suggestions and limit is suggestions.length
        callback null, suggestions
      else
        containsSeedTest = RegExp cleanSeed, 'i'
        containsOptions =
          skip      : skip
          limit     : limit - suggestions.length
          blacklist : blacklist.concat(suggestions.map (o) -> o.getId())
        @findSuggestions client, containsSeedTest, containsOptions, (err, moreSuggestions) ->
          if err
            callback err
          else
            allSuggestions = suggestions.concat moreSuggestions
            callback null, allSuggestions

  @byRelevance$ = permit 'query collection',
    success: (client, seed, options, callback) ->
      @byRelevance client, seed, options, callback
