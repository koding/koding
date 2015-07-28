koding          = require './../bongo'
{ getClientId } = require './../helpers'

module.exports = (req, res) ->

  { JUser }           = koding.models
  { password, email, tfcode } = req.body

  badRequest = (message = 'Bad request') ->
    res.status(400).send message

  return badRequest()  unless email

  if (email = email.trim()).length is 0
    return badRequest()

  { password, redirect } = req.body

  clientId =  getClientId req, res

  if clientId

    JUser.login clientId, { username : email, password, tfcode }, (err, info) ->

      { isValid : isEmail } = JUser.validateAt 'email', email, yes

      return badRequest()  unless isEmail

      if err?.name is 'VERIFICATION_CODE_NEEDED'
        return badRequest 'TwoFactor auth Enabled'

      else if err?.message is 'Access denied!'
        return badRequest()

      else if err and isEmail
        JUser.emailAvailable email, (err_, response) ->
          return badRequest()  if err_

          return if response
          then res.status(200).send response
          else badRequest 'Email is taken!'

        return

      unless info
        return res.status(500).send 'An error occurred'

      res.cookie 'clientId', info.replacementToken, { path : '/' }
      return res.status(200).send 'User is logged in!'
