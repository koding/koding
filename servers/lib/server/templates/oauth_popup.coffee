module.exports = ({error, provider})->
  error = if error? then "\"#{error}\"" else null
  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Redirecting...</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <link rel="stylesheet" href="//koding.com/hello/css/style.css">
    <link href='//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800'>
    <script>
      window.opener.KD.singletons.oauthController.authCompleted(#{error}, "#{provider}");
      window.close();
    </script>
  </head>
  <body>
    <div id="container">
      <header>
        <a href="http://koding.com">Koding.com</a>
      </header>
      <h2>
        Redirecting...
      </h2>
    </div>
  </body>
  </html>

  """
