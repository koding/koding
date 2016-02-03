request       = require 'request'
async         = require 'async'
{ isAllowed } = require '../../../../deployment/grouptoenvmapping'

module.exports = (req, res) ->
  errs = []
  urls = []
  for own key, val of KONFIG.workers
    # some of the locations can be limited to some environments, respect.
    unless isAllowed val.group, KONFIG.ebEnvName
      continue

    urls.push { name: key, url: val.versionURL }  if val?.versionURL?

  urlFns = urls.map ({ name, url }) -> (fin) ->
    request url, (err, resp, body) ->
      if err?
        errs.push({ name, err })
      else if KONFIG.version isnt body
        errs.push({ name, message: 'versions are not same' })

      fin()

  async.parallel urlFns, ->
    if Object.keys(errs).length > 0
      console.log 'VERSIONCHECK ERROR:', errs
      res.status(500).end()
    else
      res.status(200).end()
