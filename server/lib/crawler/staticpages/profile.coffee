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
  numberOfLikes = if account.counts.likes then account.counts.likes else "0"

  content  =
    """<figure class='splash' itemscope itemtype="http://schema.org/Person">
          <h2 class='splash-title' itemprop="name">
            #{username}
          </h2>
          <h3 class='splash-name'>
            [ <span itemprop="givenName">#{firstName}</span> - <span itemprop="familyName">#{lastName}</span> ]
          </h3>
          <h4 class='splash-name' itemprop="interactionCount">#{numberOfLikes} likes.</h4>
       </figure>
    """
