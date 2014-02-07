request = require 'request'

supportedServices = ['broker', 'brokerKite']

getFailoverUrl = ->
  { webProtocol: protocol, webHostname: hostname, webPort: port } =
    KONFIG.broker

  # piece the url together from the config:
  url = "#{ protocol }//#{ hostname }#{ if port then ":#{port}" else "" }"

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

    url = "#{ KONFIG.kontrold.api.url }/workers/url/#{ service }#{
      if multi
      then '?all'
      else ''
    }"

    request(url)
      .on('error', (err) -> next err  unless failover req, res, multi)
      .pipe(res)
  
  else next()  unless failover req, res, multi
