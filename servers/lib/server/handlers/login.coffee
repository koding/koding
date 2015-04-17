{ getClientId
  handleClientIdNotFound } = require './../helpers'
koding                     = require './../bongo'

module.exports = (req, res) ->

  { JUser } = koding.models
  { username, password, redirect } = req.body

  clientId =  getClientId req, res

  return handleClientIdNotFound res, req unless clientId

  JUser.login clientId, { username, password }, (err, info) ->
    if err
      return res.status(403).send err.message
    else if not info
      return res.status(500).send 'An error occurred'

    res.cookie 'clientId', info.replacementToken, path : '/'
    res.status(200).end()
