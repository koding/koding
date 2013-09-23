module.exports = ({account})->
  console.log account.profile
  getStyles  = require './styleblock'

  """
  <!doctype html>
  <html lang="en">
  <head>
    <title>Koding</title>
    #{getStyles()}
  </head>
    <body class='koding'>
      <div id='main-loading' class="kdview main-loading">
        #{putSplash(account)}
      </div>
      <div class="kdview home" id="kdmaincontainer">
      </div>
    </body>
  </html>
  """

putSplash = (account)->
  console.log account
  username   = if account.profile.nickname  then account.profile.nickname  else "A koding nickname"
  firstName  = if account.profile.firstName then account.profile.firstName else "first name of koding user"
  lastName   = if account.profile.lastName  then account.profile.lastName  else "last name of koding user"

  content  =
    """<figure class='splash'>
          <h2 class='splash-title'>
            #{username}
          </h2>
          <h3 class='splash-name'>
            [ #{firstName} - #{lastName} ]
          </h3>
       </figure>
    """
