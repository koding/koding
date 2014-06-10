class ActivityWidgetItem extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "status-update-widget-item", options.cssClass
    super options, data

    @createAuthor()
    @createCommentBox()

    @actionLinks = new ActivityActionsView
      cssClass : "comment-header"
      delegate : @commentBox.commentList
    , data

    @timeAgo = new KDTimeAgoView null, data.meta.createdAt

  createAuthor: ->
    {avatarWidth, avatarHeight} = @getOptions()
    {_id, constructorName} = @getData().account

    origin = {id: _id, constructorName}

    @avatar = new AvatarView
      size        :
        width     : avatarWidth or 50
        height    : avatarHeight or 50
      origin      : origin
      showStatus  : yes

    @author = new ProfileLinkView {origin}

  createCommentBox: ->
    {commentSettings} = @getOptions()
    commentSettings or= {}
    commentSettings.itemChildOptions or= {}
    commentSettings.itemChildOptions.showAvatar ?= no
    @commentBox = new CommentView commentSettings, @getData()

  formatContent: (str = "") ->
    str = @utils.applyMarkdown str
    str = @utils.expandTokens str, @getData()
    return  str

  pistachio: ->
    """
    <header>
      {{> @avatar}}
      <div class="content">
        {{> @author}}
        {article{@formatContent #(body)}}
      </div>
    </header>
    <footer>
      {{> @actionLinks}}
      {{> @timeAgo}}
    </footer>
    {{> @commentBox}}
    """
