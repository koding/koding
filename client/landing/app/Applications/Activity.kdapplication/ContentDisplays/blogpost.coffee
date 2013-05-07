class ContentDisplayBlogPost extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Blog Post"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 50, height: 50}
      origin  : origin

    @author = new ProfileLinkView {origin}

    @commentBox = new CommentView null, data

    @actionLinks = new ActivityActionsView
      delegate : @commentBox.commentList
      cssClass : "comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      itemClass  : TagLinkView
    , data.tags

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CBlogPostActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    if @getData().repliesCount? and @getData().repliesCount > 0
      commentController = @commentBox.commentController
      commentController.fetchAllComments 0, (err, comments)->
        commentController.removeAllItems()
        commentController.instantiateListItems comments

  applyTextExpansions:(str = "")->
    str = @utils.applyTextExpansions str, yes

  pistachio:->

    """
    {{> @header}}
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='kdview content-display-main-section activity-item blog-post'>
      <span>
        {{> @avatar}}
        <span class="author">AUTHOR</span>
      </span>
      <div class='activity-item-right-col'>
        <h3 class='blog-post-title'>{{ @applyTextExpansions #(title)}}</h3>
        <p class="blog-post-body has-markdown">{{Encoder.htmlDecode #(html)}}</p>
        <footer class='clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> by {{> @author}}
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
          </div>
          {{> @actionLinks}}
        </footer>
        {{> @commentBox}}
      </div>
    </div>
    """

class StaticBlogPostListItem extends KDListItemView
  constructor:(options,data)->
    super options,data
    @postDate = new Date @getData().meta.createdAt
    @postDate = @postDate.toLocaleString() # "dddd, mmmm dS, yyyy at h:MM:ss TT"
    # postDate = require('dateformat')(blog.meta.createdAt,"dddd, mmmm dS, yyyy at h:MM:ss TT")

    @setClass 'content-item'

  viewAppended:->
    log 'viewAppended'
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="title"><span class="text">#{@getData().title}</span><span class="create-date">#{@postDate}</span></div>
    <div class="has-markdown">
      <span class="data">#{Encoder.htmlDecode @getData().html}</span>
    </div>
    """
