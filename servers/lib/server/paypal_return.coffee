koding  = require './bongo'

{
  serve
  findUsernameFromSession
} = require './helpers'

{ post }   = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

templateFn = (err, res)->
  err = if err? then "\"#{err.message or err}\"" else null
  template = """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <script>
          window.opener.require('kd').singletons.paymentController.paypalReturn(#{err});
          window.close();
        </script>
      </head>
    </html>
  """

  serve template, res

###*
 * This function requires you to test with ngrok and https protocol.
 * Please make sure that it's not your local url when testing this.
###
module.exports = (req, res) ->
  {token}    = req.query
  {clientId} = req.cookies

  findUsernameFromSession req, res, (err, username)->
    return templateFn err  if err

    koding.models.JAccount.one {"profile.nickname" : username }, (err, account)->
      return templateFn err  if err

      params = { token, accountId : account._id }
      post "/api/social/payments/paypal/return", params, (err)-> templateFn err, res
