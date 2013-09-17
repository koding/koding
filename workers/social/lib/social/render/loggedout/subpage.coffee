module.exports = ({account})->

  getStyles       = require './../styleblock'
  getScripts      = require './../scriptblock'

  """
  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
  </head>
  <body class='koding'>

    <!--[if IE]>
    <script>(function(){window.location.href='/unsupported.html'})();</script>
    <![endif]-->

    <div class="kdview home" id="kdmaincontainer">
      <div id='main-loading' class="kdview main-loading"><figure class='pulsing'><ul><li/><li/><li/><li/><li/><li/></ul></figure></div>
    </div>

    #{KONFIG.getConfigScriptTag { roles: ['guest'], permissions: [] } }
    #{getScripts()}

  </body>
  </html>
  """
