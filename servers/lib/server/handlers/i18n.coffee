request = require 'request'

module.exports = locales = (req, res) ->

  { lang, namespace } = req.params
  { publicHostname } = KONFIG

  lang      or= 'en'
  namespace or= 'default'

  requestOptions  =
    url     : "#{publicHostname}/a/locales/#{lang}/#{namespace}.json"
    headers : { 'User-Agent': 'request' }
    timeout : 3000

  request requestOptions, (err, response, body) ->

    return res.status(400).send err.code  if err

    return res.status(200).send body
