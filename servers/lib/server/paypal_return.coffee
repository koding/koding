{ serve } = require './helpers'

module.exports = (req, res) ->
  {token}  = req.query
  template = """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <script>
          window.opener.KD.singletons.paymentController.paypalReturn();
          window.close();
        </script>
      </head>
    </html>
  """

  serve template, res
