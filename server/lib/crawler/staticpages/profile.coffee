{argv} = require 'optimist'
{uri} = require('koding-config-manager').load("main.#{argv.c}")

createLinkToStatusUpdate = (createDate, slug) ->
  content =
    """
    <a href="#{uri.address}/#!/Activity/#{slug}">#{createDate}</a>
    """
  return content

createStatusUpdateNode = (statusUpdate, authorFullName, authorNickname)->
  {
    formatDate
  }          = require '../helpers'
  createdAt = formatDate statusUpdate.meta.createdAt
  linkToStatusUpdate = createLinkToStatusUpdate createdAt, statusUpdate.slug
  statusUpdateContent = ""
  if statusUpdate.body
    statusUpdateContent =
    """
    <li itemtype="http://schema.org/Comment" itemscope itemprop="comment">
        <span itemprop="commentText">#{statusUpdate.body}</span> -
        <span itemprop="commentTime"></span>
        at #{linkToStatusUpdate}
    </li>
    """
  return statusUpdateContent

createLinkToUserProfile = (fullName, nickname) ->
  content =
    """
      <a href=\"#{uri.address}/#!/#{nickname}\">#{fullName}</a>
    """
  return content

getStatusUpdates = (statusUpdates, authorFullName, authorNickname) ->
  linkToProfile = createLinkToUserProfile authorFullName, authorNickname
  if statusUpdates?.length > 0
    updates = (createStatusUpdateNode(statusUpdate, authorFullName, authorNickname) for statusUpdate in statusUpdates)
    updatesContent = "<h4>Last status updates from #{linkToProfile}:</h4>"
    updatesContent += "<ol>"
    updatesContent += updates.join("")
    updatesContent += "</ol>"
  else
    updatesContent = ""
  return updatesContent


module.exports = ({account, statusUpdates})->
  getStyles  = require './styleblock'
  getGraphMeta  = require './graphmeta'
  {
    formatDate
    getFullName
  }          = require '../helpers'

  {profile:{nickname}} = account if account
  fullName = getFullName account
  sUpdates = getStatusUpdates statusUpdates, fullName, nickname, (err, sUpdates) ->
  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>#{nickname} - Koding</title>
    #{getGraphMeta()}
  </head>
    <body class='koding' itemscope itemtype="http://schema.org/WebPage">
      #{putContent(account, sUpdates)}
    </body>
  </html>
  """

putContent = (account, sUpdates)->
  {profile:{nickname, firstName, lastName}} = account if account
  nickname or= "A koding nickname"
  firstName or= "a koding "
  lastName or= "user"

  numberOfLikes = if account.counts.likes then account.counts.likes else "0"
  imgURL = "https://gravatar.com/avatar/#{account.profile.hash}?size=90&amp;d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.90.png"

  content  =
    """
      <a href="#{uri.address}">Koding</a><br />
      <figure itemscope itemtype="http://schema.org/Person" title="#{firstName} #{lastName}">
          <h2itemprop="name">
            <a href="#{uri.address}/#!/#{nickname}">#{nickname}</a>
          </h2>
          <figcaption>
            <img src="#{imgURL}" itemprop="image"/> <br>
            <a href="#{uri.address}/#!/#{nickname}">
              <span itemprop="givenName">#{firstName}</span>
              <span itemprop="familyName">#{lastName}</span>
            </a>
            <br>
            <span itemprop="interactionCount">#{numberOfLikes} likes.</span>
          </figcaption>
       </figure>
       #{sUpdates}
    """
