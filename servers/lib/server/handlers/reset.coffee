koding         = require './../bongo'

module.exports = (req, res) ->
  { JPasswordRecovery } = koding.models
  { recoveryToken: token, password } = req.body

  return res.status(400).send 'Invalid token!'  if not token
  return res.status(400).send 'Invalid password!'  if not password

  JPasswordRecovery.resetPassword token, password, (err, username) ->
    return res.status(400).send err.message  if err?
    res.status(200).send({ username })
