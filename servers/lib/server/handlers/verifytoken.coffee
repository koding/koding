koding = require './../bongo'

module.exports = (req, res) ->

  { JPasswordRecovery } = koding.models
  { token } = req.params

  JPasswordRecovery.validate token, (err) ->
    return res.redirect 301, '/VerificationFailed'  if err?

    res.redirect 301, '/Verified'
