querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateDefaultRequestParams } = require '../index'


generateGetProfileRequestParams = (opts = {}) ->

  url                  = generateUrl { route : "-/profile/#{opts.email}" }
  defaultRequestParams = generateDefaultRequestParams { url }
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateGetProfileRequestParams
}
