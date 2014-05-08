class CommentView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "comment-container", options.cssClass

    super options, data

    @createSubViews data
    @resetDecoration()
    @attachListeners()

    @setFixedHeight fixedHeight  if {fixedHeight} = options


  setFixedHeight: (maxHeight) ->

    @setClass "fixed-height"
    @commentList.$().css {maxHeight}


  createSubViews: (data) ->

    @commentList = new KDListView
      type          : "comments"
      itemClass     : CommentListItemView
      delegate      : this
    , data

    @commentController        = new CommentListViewController view: @commentList
    @addSubView showMore      = new CommentViewHeader delegate: @commentList, data
    @addSubView @commentController.getView()
    @addSubView @commentForm  = new NewCommentForm delegate: @commentController

    @commentForm.on "Submit", @commentController.bound "reply"

    @commentList.on 'ReplyLinkClicked', (username) =>
      {input} = @commentForm
      value = input.getValue()
      value = if value.indexOf("@#{username}") >= 0 then value else if value.length is 0 then "@#{username} " else "#{value} @#{username} "

      input.setFocus()
      input.setValue value

    @commentList.on "OwnCommentWasSubmitted", -> @getDelegate()?.emit "RefreshTeaser"

    @commentList.on "OwnCommentHasArrived", ->

      showMore.ownCommentArrived()
      @getDelegate()?.emit "RefreshTeaser"

    @commentList.on "CommentIsDeleted", ->

      showMore.ownCommentDeleted()

    @on "RefreshTeaser", ->

      @parent?.emit "RefreshTeaser"

    @commentList.emit "BackgroundActivityFinished"


  attachListeners: ->

    @commentList.on "commentInputReceivedFocus", @bound "decorateActiveCommentState"
    @commentList.on "CommentViewShouldReset", @bound "resetDecoration"

    @commentList.on "CommentLinkReceivedClick", (event) =>

      @commentForm.makeCommentFieldActive()
      @commentForm.input.setFocus()

    @commentList.on "CommentCountClicked", =>

      @commentList.emit "AllCommentsLinkWasClicked"


  decorateNoCommentState: ->

    @unsetClass "active-comment"
    @unsetClass "commented"
    @setClass "no-comment"


  decorateCommentedState: ->

    @unsetClass "active-comment"
    @unsetClass "no-comment"
    @setClass "commented"


  decorateActiveCommentState: ->

    @unsetClass "no-comment"
    @setClass "active-comment"


  decorateItemAsLiked: (likeObj) ->

    if likeObj?.results?.likeCount > 0
      @setClass "liked"
    else
      @unsetClass "liked"
    @ActivityActionsView.setLikedCount likeObj


  resetDecoration: ->

    if @getData().repliesCount
    then @decorateCommentedState()
    else @decorateNoCommentState()


  render: ->

    super

    @resetDecoration()
