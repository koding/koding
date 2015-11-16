_           = require 'lodash'
request     = require 'request'
KodingError = require '../../error'

module.exports = fallbackToIframely = (url, callback) ->

  { apiKey, url : iframelyUrl } = KONFIG.iframely

  request "#{iframelyUrl}?url=#{url}&api_key=#{apiKey}", (err, res, result) ->

    return callback err, [result]  if err

    try
      result = JSON.parse result
    catch e
      return callback e

    if result.type is 'photo'
      mappedResult        = _.assign {}, result
      mappedResult.images = [result]
      result              = mappedResult

      callback err, [result]

    else
      callback new KodingError 'Embed fallback error'
