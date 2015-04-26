koding = require './../bongo'

module.exports = (req, res) ->
  { JPasswordRecovery } = koding.models
  { email } = req.body

  return res.status(400).send 'Invalid email!'  if not email

  JPasswordRecovery.recoverPasswordByEmail { email }, (err) ->
    return res.status(403).send err.message  if err?

    res.status(200).end()