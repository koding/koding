{Base}   = require 'bongo'
{extend} = require 'underscore'

embedly  = require 'embedly'

module.exports = class Embedly extends Base

  {signature} = require 'bongo'

  @share()

  @set
    sharedMethods :
      static      :
        fetch     : [
          (signature String, Object, Function)
          (signature [String], Object, Function)
        ]

  @fetch = (urls, options = {}, callback) ->
    urls = [urls]  unless Array.isArray urls

    options.urls      = urls
    options.maxWidth ?= 150

    key = KONFIG.embedly.apiKey
    new embedly {key}, (err, api) ->
      return callback err  if err
      api.oembed options, callback
