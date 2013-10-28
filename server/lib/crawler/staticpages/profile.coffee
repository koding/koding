module.exports = ({account})->
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'

  """
  <!doctype html>
  <html lang="en" itemscope="" itemtype="http://schema.org/WebPage">
  <head>
    <title>Koding</title>
    #{getStyles()}
    #{getGraphMeta()}
  </head>
    <body class='koding' itemscope itemtype="http://schema.org/WebPage">
      <div id='main-loading' class="kdview main-loading">
        #{putContent(account)}
      </div>
      <div class="kdview home" id="kdmaincontainer">
      </div>
    </body>
  </html>
  """

putContent = (account)->
  {profile:{nickname, firstName, lastName}} = account if account
  nickname or= "A koding nickname"
  firstName or= "a koding "
  lastName or= "user"

  numberOfLikes = if account.counts.likes then account.counts.likes else "0"
  imgURL = "https://gravatar.com/avatar/#{account.profile.hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png"

  content  =
    """<figure class='splash' itemscope itemtype="http://schema.org/Person">
          <h2 class='splash-title' itemprop="name">
            #{nickname}
          </h2>
          <h3 class='splash-name'>
            <img class="avatarview" style="width: 90px; height: 90px;" src="#{imgURL}" itemprop="image"/>
            [ <span itemprop="givenName">#{firstName}</span> <span itemprop="familyName">#{lastName}</span> ]
          </h3>
          <br />
          <h4 class='splash-name' itemprop="interactionCount">#{numberOfLikes} likes.</h4>
       </figure>
    """
