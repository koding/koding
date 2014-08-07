{argv}              = require 'optimist'
{uri, client}       = require('koding-config-manager').load("main.#{argv.c}")


getAvatarImageUrl = (hash, avatar)->
  imgURL   = "//gravatar.com/avatar/#{hash}?size=37&d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.140.png&r=g"
  if avatar
    imgURL = "//i.embed.ly/1/display/crop?grow=false&width=37&height=37&key=94991069fb354d4e8fdb825e52d4134a&url=#{encodeURIComponent avatar}"
  return imgURL

createAvatarImage = (hash, avatar)=>
  imgURL = getAvatarImageUrl hash, avatar
  """
  <img width="37" height="37" src="#{imgURL}" style="opacity: 1;" itemprop="image" />
  """

createCreationDate = (createdAt, slug)->
  """
  <time class="kdview">#{createdAt}</time>
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
        <a class="avatarview" href="/#{comment.authorNickname}" style="background-image: none; background-size: 38px 38px;">
          #{avatarImage}
        </a>
        <div class="comment-contents clearfix">
          <a href="#{uri.address}/#{nickname}" class="profile">Sinan Yasar</a>
          <div class="comment-body-container">
            <p data-paths="body" id="el-56">#{message.body}</p>
          </div>
        </div>
      </div>

      """

  return commentsList

getActivityContent = (activityContent)->
  slugWithDomain = "#{uri.address}/Activity/Public/#{activityContent.slug}"
  {body, nickname, fullName, hash, avatar, createdAt, commentCount, likeCount} = activityContent
  avatarImage   = createAvatarImage hash, avatar
  createdAt     = createCreationDate createdAt, activityContent.slug
  author        = createAuthor fullName, nickname

  {formatBody} = require './bodyrenderer'
  body = formatBody body
  commentsList = prepareComments activityContent

  content  =
    """
    <div class="kdview kdlistitemview kdlistitemview-activity static activity-item status">
      <div class="activity-content-wrapper">
        <a class="avatarview author-avatar" href="#{uri.address}/#{nickname}" style="background-image: none; background-size: 37px 37px;">
          #{avatarImage}
        </a>
        <div class="meta">
          <a href="#{uri.address}/#{nickname}" class="profile">#{fullName}</a>
          #{createdAt}
        </div>
        <article data-paths="body" id="el-26">
          #{body}
        </article>
        <div class="kdview activity-actions comment-header">
          <span class="logged-in action-container">
            <a class="custom-link-view" href="#">
              <span class="title" data-paths="title" id="el-41">Comment</span>
            </a>
            <a class="custom-link-view count" href="#">
              <span data-paths="repliesCount" id="el-42">#{commentCount}</span>
            </a>
          </span>
          <span class="optional action-container">
            <a class="custom-link-view" href="#">
              <span class="title" data-paths="title" id="el-43">Share</span>
            </a>
          </span>
        </div>
      </div>
      <div class="kdview comment-container fixed-height">
        <div class="kdview listview-wrapper">
          <div class="kdview kdscrollview">
            <div class="kdview kdlistview kdlistview-comments">
              #{commentsList}
            </div>
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
