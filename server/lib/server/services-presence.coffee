request = require 'request'

supportedServices = ['broker', 'premiumBroker', 'brokerKite', 'premiumBrokerKite']

getFailoverUrl = (serviceName)->
  { webProtocol, failoverUri, port } = KONFIG[serviceName]

  # piece the url together from the config:
  url = "#{ webProtocol }//#{ failoverUri }#{ if port then ":#{port}" else "" }"
  console.warn "Serving failover url", url
  return url

failover = (req, res, multi) ->
  if req.params.service in supportedServices
    url = getFailoverUrl req.params.service
    res.set 'Content-Type', 'application/json'
    res.send if multi then [url] else JSON.stringify url
    yes
  else
    no

sendBody = (res, body)->
  res.set 'Content-Type', 'application/json'
  return res.send 200, body


module.exports = (req, res, next) ->
  { params, query } = req

  { service } = params

  return next()  unless service in supportedServices

  multi = query.all?

  if KONFIG.runKontrol # let kontrol provide the url

    { url, port } = KONFIG.kontrold.api

    url = "#{ url }:#{ port }/workers/url/#{ service }#{
      if multi
      then '?all'
      else ''
    }"

    request url, (error, response, body) ->
      if not error and response.statusCode is 200 and body

        # we can query for multiple services
        if multi
          try kontrolResponse = JSON.parse body

          if Array.isArray kontrolResponse
            if kontrolResponse.length isnt 0
              return sendBody res, body

        # if query is not multiple then
        # no need for checking array length
        else return sendBody res, body

      return  if failover req, res, multi
      return next()

  else next()  unless failover req, res, multi
