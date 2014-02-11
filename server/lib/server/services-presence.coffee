request = require 'request'

supportedServices = ['broker', 'brokerKite']

getFailoverUrl = ->
  { webProtocol: protocol, webHostname: hostname, webPort: port } =
    KONFIG.broker

  # piece the url together from the config:
  url = "#{ protocol }//#{ hostname }#{ if port then ":#{port}" else "" }"
  console.warn "Serving failover url", url
  return url

failover = (req, res, multi) ->
  if req.params.service in supportedServices
    url = getFailoverUrl()
    res.set 'Content-Type', 'application/json'
    res.send if multi then [url] else JSON.stringify url
    yes
  else
    no

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
        res.set 'Content-Type', 'application/json'
        return res.send 200, body

      return  if failover req, res, multi
      return next()

  else next()  unless failover req, res, multi
