koding  = require './../bongo'
request = require 'request'
KONFIG  = require 'koding-config-manager'


getUri = (identifier, format = 'json') ->

  return if identifier
  then "https://koding.wufoo.com/api/v3/forms/#{identifier}.#{format}"
  else "https://koding.wufoo.com/api/v3/forms.#{format}"


module.exports = (req, res, next) ->

  { identifier, format } = req.params

  uri = getUri identifier, format

  console.log uri

  request
    uri    : uri
    method : 'GET'
    auth   :
      'username'        : API_KEY
      'password'        : 'thisdoesntmatter'
      'sendImmediately' : false
  , (err, response, body) ->

    return res.status(500).send 'an error occured'  if err or not body
    return res.status(200).send body