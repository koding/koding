module.exports = ({account})->
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'

  {profile:{nickname}} = account if account

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{nickname} - Koding</title>
    #{getGraphMeta()}
  </head>
    <body class='koding' itemscope itemtype="http://schema.org/WebPage">
      #{putContent(account)}
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
    """<figure itemscope itemtype="http://schema.org/Person" title="#{firstName} #{lastName}">
          <h2itemprop="name">
            #{nickname}
          </h2>
          <figcaption>
            <img src="#{imgURL}" itemprop="image"/> <br>
            <span itemprop="givenName">#{firstName}</span> <span itemprop="familyName">#{lastName}</span><br>
            <span itemprop="interactionCount">#{numberOfLikes} likes.</span>
          </figcaption>
       </figure>
    """
