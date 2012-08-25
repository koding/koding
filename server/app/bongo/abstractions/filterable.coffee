class Filterable
  {secure, ObjectId} = require 'bongo'
  
  @findSuggestions = ()->
    throw new Error "Filterable must implement static method findSuggestions!"

  @byRelevance = secure (client, seed, options, callback)->
    [callback, options] = [options, callback] unless callback
    {limit,blacklist}  = options
    limit     ?= 10
    blacklist or= []
    blacklist = blacklist.map(ObjectId)
    cleanSeed = seed.replace(/[^\w\s]/).trim() #TODO: this is wrong for international charsets
    startsWithSeedTest = RegExp '^'+cleanSeed, "i"
    startsWithOptions = {limit, blacklist}
    @findSuggestions startsWithSeedTest, startsWithOptions, (err, suggestions)=>
      if err then callback err
      else if limit is suggestions.length then callback null, suggestions
      else
        containsSeedTest = RegExp cleanSeed, 'i'
        containsOptions =
          limit     : limit-suggestions.length
          blacklist : blacklist.concat(suggestions.map (o)-> o.getId())
        @findSuggestions containsSeedTest, containsOptions, (err, moreSuggestions)->
          if err
            callback err
          else
            allSuggestions = suggestions.concat moreSuggestions
            callback null, allSuggestions