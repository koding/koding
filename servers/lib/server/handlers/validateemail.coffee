koding          = require './../bongo'
{ getClientId } = require './../helpers'

module.exports = (req, res) ->

  { JUser }           = koding.models
  { password, email } = req.body

  return res.status(400).send 'Bad request'  unless email?

  { password, redirect } = req.body

  clientId =  getClientId req, res

  if clientId

    JUser.login clientId, { username : email, password }, (err, info) ->

      {isValid : isEmail} = JUser.validateAt 'email', email, yes

      if err and isEmail
        JUser.emailAvailable email, (err_, response) ->
          return res.status(400).send 'Bad request'  if err_

          return if response
          then res.status(200).send response
          else res.status(400).send 'Email is taken!'

        return

      unless info
        return res.status(500).send 'An error occurred'

      res.cookie 'clientId', info.replacementToken, path : '/'
      return res.status(200).send 'User is logged in!'
