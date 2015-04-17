request  = require 'request'
{ dash } = require 'bongo'

module.exports = (req, res) ->
  errs = []
  urls = []
  for own key, val of KONFIG.workers
    urls.push {name: key, url: val.versionURL}  if val?.versionURL?

  urlFns = urls.map ({name, url})->->
    request url, (err, resp, body)->
      if err?
        errs.push({ name, err })
      else if KONFIG.version isnt body
        errs.push({ name, message: "versions are not same" })

      urlFns.fin()

  dash urlFns, ->
    if Object.keys(errs).length > 0
      console.log "VERSIONCHECK ERROR:", errs
      res.status(500).end()
    else
      res.status(200).end()