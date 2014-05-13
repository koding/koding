class ActivityActionsView extends KDView

  contextMenu = null

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "activity-actions comment-header", options.cssClass

    super options, data

    @commentLink  = new CustomLinkView title: "Comment"

    @commentCount = new ActivityCommentCount
      cssClass    : 'count'
      tooltip     :
        title     : "Show all"
      click       : (event) =>
        KD.utils.stopDOMEvent event
        @getDelegate().emit "CommentCountClicked", this
    , data

    @shareLink = new CustomLinkView
      title : "Share"
      click : (event) =>

        KD.utils.stopDOMEvent event

        data = @getData()
        if data?.group? and data.group isnt "koding"
          shareUrl = "#{KD.config.mainUri}/#{data.group}/Activity/#{data.slug}"
        else
          shareUrl      = "#{KD.config.mainUri}/Activity/#{data.slug}"

        contextMenu   = new KDContextMenu
          cssClass    : "activity-share-popup"
          type        : "activity-share"
          delegate    : this
          x           : @shareLink.getX() + 25
          y           : @shareLink.getY() - 7
          menuMaxWidth: 400
          menuMinWidth: 192
          lazyLoad    : yes
        , customView  : new ActivitySharePopup delegate: this, url: shareUrl

        KD.mixpanel "Activity share, click"

    @likeLink = new ActivityLikeLink null, data

    @loader = new KDLoaderView
      cssClass      : 'action-container'
      size          :
        width       : 16
      loaderOptions :
        color       : '#6B727B'


  attachListeners: ->

    commentList = @getDelegate()

    commentList.on 'BackgroundActivityStarted',  @loader.bound 'show'
    commentList.on 'BackgroundActivityFinished', @loader.bound 'hide'

    @commentLink.on "click", (event)=>
      @utils.stopDOMEvent event
      commentList.emit "CommentLinkReceivedClick", event, this


  viewAppended: ->

    @setTemplate @pistachio()
    @template.update()
    @attachListeners()
    @loader.hide()


  pistachio: ->

    """
    <span class='logged-in action-container'>
    {{> @likeLink}}
    </span>
    <span class='logged-in action-container'>
    {{> @commentLink}}{{> @commentCount}}
    </span>
    <span class='optional action-container'>
    {{> @shareLink}}
    </span>
    {{> @loader}}
    """
