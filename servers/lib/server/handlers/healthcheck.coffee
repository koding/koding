async         = require 'async'
request       = require 'request'
_             = require 'underscore'
{ isAllowed } = require '../../../../deployment/grouptoenvmapping'

module.exports = (req, res) ->

  { workers, publicPort, ebEnvName } = KONFIG

  errs = []
  urls = []

  for own _, worker of workers
    # some of the locations can be limited to some environments, respect.
    unless isAllowed worker.group, ebEnvName
      continue

    if worker.healthCheckURLs?.length
      urls.push url for url in worker.healthCheckURLs

  urls.push("http://localhost:#{publicPort}/-/versionCheck")

  urlFns = urls.map (url) -> (fin) ->
    request url, (err, resp, body) ->
      errs.push({ url, err })  if err?
      fin()

  async.parallel urlFns, ->
    if Object.keys(errs).length > 0
      console.log 'HEALTHCHECK ERROR:', errs
      res.status(500).end()
    else
      res.status(200).end()
