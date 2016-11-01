koding               = require './../bongo'
{ getClientId
  setSessionCookie } = require './../helpers'


badRequest = (res, message = 'Bad request') -> res.status(400).send message


generateCheckEmailCallback = (res, email, JUser) ->

  unless KONFIG.environment is 'production'
    res.header 'Access-Control-Allow-Origin', 'http://dev.koding.com:4000'

  return (err, info) ->
    { isValid : isEmail } = JUser.validateAt 'email', email, yes

    return badRequest res  unless isEmail

    if err?.name is 'VERIFICATION_CODE_NEEDED'
      return badRequest res, 'TwoFactor auth Enabled'

    else if err?.message is 'Access denied!'
      return badRequest res

    else if err and isEmail
      JUser.emailAvailable email, (err_, response) ->
        return badRequest res  if err_

        return if response
        then res.status(200).send response
        else badRequest res, 'Email is taken!'

      return

    unless info
      return res.status(500).send 'An error occurred'

    setSessionCookie res, info.replacementToken
    return res.status(200).send 'User is logged in!'


module.exports = (req, res) ->

  { JUser }                   = koding.models
  { password, email, tfcode } = req.body

  return badRequest res  unless email

  if (email = email.trim()).length is 0
    return badRequest res

  { password, redirect } = req.body

  clientId =  getClientId req, res

  return badRequest res  unless clientId

  checkEmail = generateCheckEmailCallback res, email, JUser
  JUser.login clientId, { username : email, password, tfcode }, checkEmail
