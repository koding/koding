{argv}              = require 'optimist'
{uri, client}       = require('koding-config-manager').load("main.#{argv.c}")


getAvatarImageUrl = (hash, avatar)->
  imgURL   = "//gravatar.com/avatar/#{hash}?size=90&d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.140.png&r=g"
  if avatar
    imgURL = "//i.embed.ly/1/display/crop?grow=false&width=90&height=90&key=94991069fb354d4e8fdb825e52d4134a&url=#{encodeURIComponent avatar}"
  return imgURL

createAvatarImage = (hash, avatar)=>
  imgURL = getAvatarImageUrl hash, avatar
  """
  <img width="42" height="42" src="#{imgURL}" style="opacity: 1;" itemprop="image" />
  """

createCreationDate = (createdAt, slug)->
  """
    <a href="#{uri.address}/Activity/Post/#{slug}" style="text-decoration:none">
      <time class="kdview"><span itemprop=\"dateCreated\">#{createdAt}</span></time>
    </a>
  """

createAuthor = (accountName, nickname)->
  return "<a href=\"#{uri.address}/#{nickname}\"><span itemprop=\"name\">#{accountName}</span></a>"

prepareComments = (activityContent)->
  commentsList = ""
  return commentsList  unless activityContent?.replies

  activityContent.replies.reverse()
  for comment in activityContent.replies
    {replier, message} = comment
    {hash, avatar, nickname, fullName} = replier
    avatarImage = createAvatarImage hash, avatar
    commentsList +=
      """
        <div class="kdview kdlistitemview kdlistitemview-comment">
          <a class="avatarview" href="/#{comment.authorNickname}" style="background-image: none; background-size: 42px;">
            #{avatarImage}
          </a>
          <div class="comment-contents clearfix">
            <a href="#{uri.address}/#{nickname}" class="profile" itemprop="name">#{fullName}</a>
            <div class="comment-body-container">
              <p itemprop="commentText">#{message.body}</p>
            </div>
          </div>
        </div>
      """

  return commentsList

prepareLikes = (activityContent)->
  return ""  unless activityContent?.likers?.length
  likeList = """<div class="kdview like-summary">"""

  likerCount = activityContent.likers.length
  for i in [0...likerCount]
    {nickname, fullName} = activityContent.likers[i]
    likeList += """<a href="#{uri.address}/#{nickname}" class="profile"><span>#{fullName}</span></a>"""
    likeList += addLikeSeperator i, likerCount

  likeList += "<span> liked this.</span></div>"

addLikeSeperator = (index, count) ->
  return ", "    if index < count - 2
  return " and " if index < count - 1
  return ""      if index == count - 1

getActivityContent = (activityContent)->
  slugWithDomain = "#{uri.address}/Activity/Public/#{activityContent.slug}"
  {body, nickname, fullName, hash, avatar, createdAt, commentCount, likeCount} = activityContent
  avatarImage   = createAvatarImage hash, avatar
  createdAt     = createCreationDate createdAt, activityContent.slug
  author        = createAuthor fullName, nickname

  {formatBody} = require './bodyrenderer'
  body = formatBody body
  commentsList = prepareComments activityContent

  likeList = prepareLikes activityContent

  content  =
    """
    <div class="kdview kdlistitemview kdlistitemview-activity activity-item status">
      <div class="activity-content-wrapper static-feed">
        <a class="avatarview author-avatar" href="#{uri.address}/#{nickname}" style="background-image: none; background-size: 42px;">
            #{avatarImage}
        </a>

        <div class="meta">
          <a href="#{uri.address}/#{nickname}" class="profile">
            <span>#{fullName}</span>
          </a>
          <footer>
            #{createdAt}
            <span class="location">San Francisco</span>
          </footer>

        </div>

        <article data-paths="body">
          <p>
            #{body}
          </p>
        </article>
        #{likeList}

        <div class="kdview comment-container fixed-height active-comment commented">
          <div class="kdview kdlistview kdlistview-comments">
            #{commentsList}
          </div>
        </div>
      </div>
    </div>
    """
  return content

module.exports = {
  getAvatarImageUrl
  getActivityContent
}
