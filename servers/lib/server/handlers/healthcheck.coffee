request  = require 'request'
{ dash } = require 'bongo'
_        = require 'underscore'

module.exports = (req, res) ->

  { workers, publicPort } = KONFIG

  errs = []
  urls = []

  for own _, worker of workers
    urls.push worker.healthCheckURL  if worker.healthCheckURL

  urls.push("http://localhost:#{publicPort}/-/versionCheck")

  urlFns = urls.map (url)->->
    request url, (err, resp, body)->
      errs.push({ url, err })  if err?
      urlFns.fin()

  dash urlFns, ->
    if Object.keys(errs).length > 0
      console.log "HEALTHCHECK ERROR:", errs
      res.status(500).end()
    else
      res.status(200).end()