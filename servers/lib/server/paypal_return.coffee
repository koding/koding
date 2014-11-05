koding  = require './bongo'

{
  serve
  findUsernameFromSession
} = require './helpers'

{ post }   = require (
  "../../../workers/social/lib/social/models/socialapi/requests.coffee"
)

module.exports = (req, res) ->
  {token}    = req.query
  {clientId} = req.cookies

  findUsernameFromSession req, res, (err, username)->
    # if err or !username

    koding.models.JAccount.one {"profile.nickname" : username }, (err, account)->
      # if err

      params = { token, accountId : account._id }
      post "/payments/paypal/return", params, (err, response)->
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
