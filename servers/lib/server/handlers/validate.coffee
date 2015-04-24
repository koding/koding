koding  = require './../bongo'

module.exports = (req, res) ->
  { JUser } = koding.models
  { fields } = req.body

  unless fields?
    res.status(400).send 'Bad request'
    return

  validations = Object.keys fields
    .filter (key) -> key in ['username', 'email']
    .reduce (memo, key) ->
      { isValid, message } = JUser.validateAt key, fields[key], yes
      memo.fields[key] = { isValid, message }
      memo.isValid = no  unless isValid
      memo
    , { fields: {} }

  res.status(if validations.isValid then 200 else 400).send validations
