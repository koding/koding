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
          window.opener.KD.singletons.paymentController.paypalReturn(#{err});
          window.close();
        </script>
      </head>
    </html>
  """

  serve template, res

module.exports = (req, res) ->
  {token}    = req.query
  {clientId} = req.cookies

  findUsernameFromSession req, res, (err, username)->
    return templateFn err  if err

    koding.models.JAccount.one {"profile.nickname" : username }, (err, account)->
      return templateFn err  if err

      params = { token, accountId : account._id }
      post "/payments/paypal/return", params, (err)-> templateFn err, res
