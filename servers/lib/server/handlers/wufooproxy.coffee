request   = require 'request'
{ wufoo } = require 'koding-config-manager'

API_KEY = wufoo

module.exports = (req, res, next) ->

  { identifier } = req.params

  formURI = "https://koding.wufoo.com/api/v3/forms/#{identifier}/entries.json"

  request
    uri               : formURI
    method            : 'POST'
    auth              :
      username        : API_KEY
      password        : 'thisdoesntmatter'
      sendImmediately : false
    form              : req.body
  , (err, response, body) ->

    return res.status(500).send 'an error occured'  if err or not body

    try
      body = JSON.parse body
    catch e
      return res.status(500).send 'an error occured'

    { Success, ErrorText, FieldErrors, RedirectUrl } = body

    return res.status(400).send { ErrorText, FieldErrors }  unless Success
    return res.status(200).send { Success, RedirectUrl }
