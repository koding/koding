class ActivitySharePopup extends JView

  constructor: (options={}, data)->
    options.cssClass = "share-popup"
    super

    {url} = @getOptions()

    @urlInput = new KDInputView
      cssClass      : "share-input"
      type          : "text"
      placeholder   : "shortening..."
      width         : 50

    unless @getDelegate()._shorten
      KD.utils.shortenUrl url, (shorten, data)=>

        url = if data then @getDelegate()._shorten = shorten else shorten

        @urlInput.setValue shorten
        @urlInput.$().select()
    else
      url = @getDelegate()._shorten
      @urlInput.setValue url

    @once "viewAppended", =>
      @urlInput.$().select()

    @twitterShareButton = new KDButtonView
      cssClass  : "share-twitter"
      iconOnly  : yes
      iconClass : "twitter"
      callback  : =>
        tags = ("##{tag.slug}"  for tag in @getDelegate().getData().tags)
        tags = _.unique(tags).join " "
        shareText = "#{@getDelegate().getData().body} #{tags} - #{url}"
        window.open(
          "https://twitter.com/intent/tweet?text=#{encodeURIComponent shareText}&via=koding&source=koding",
          "twitter-share-dialog",
          "width=500,height=350,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
        )

    @openNewTabButton = new CustomLinkView
      title       : ""
      href        : url
      target      : url
      icon        :
        cssClass  : 'new-page'
        placement : 'right'

  pistachio: ->
    """
    {{> @urlInput}}
    {{> @openNewTabButton}}
    <div>
      {{> @twitterShareButton}}
    </div>
    """

class ActivityActionsView extends KDView

  constructor:->
    super

    activity = @getData()

    @commentLink  = new ActivityActionLink
      partial : "Comment"

    @commentCount = new ActivityCommentCount
      tooltip     :
        title     : "Show all"
      click       : (event)=>
        # event.preventDefault()
        @getDelegate().emit "CommentCountClicked", @
    , activity

    @shareLink    = new ActivityActionLink
      partial     : "Share"

      click:(event)=>
        shareUrl      = "https://koding.com/Activity/#{@getData().slug}"
        contextMenu   = new JContextMenu
          cssClass    : "activity-share-popup"
          delegate    : @
          x           : @getX() - 15
          y           : @getY() - 42
          arrow       :
            placement : "bottom"
            margin    : 90
          lazyLoad    : yes
        , customView  : new ActivitySharePopup delegate: this, url: shareUrl

        new KDOverlayView
          parent      : KD.singletons.mainView.mainTabView.activePane
          transparent : yes

    @likeView     = new LikeView {checkIfLikedBefore: no}, activity
    @loader       = new KDLoaderView size : width : 14

    unless KD.isLoggedIn()
      @commentLink.setTooltip title: "Login required"
      @likeView.likeLink.setTooltip title: "Login required"
      KD.getSingleton("mainController").on "accountChanged.to.loggedIn", =>
        delete @likeView.likeLink.tooltip
        delete @commentLink.tooltip

    @attachListeners()

  viewAppended:->

    @setClass "activity-actions"
    @setTemplate @pistachio()
    @template.update()
    @attachListeners()
    @loader.hide()

  pistachio:->

    """
    {{> @loader}}
    {{> @commentLink}}{{> @commentCount}} ·
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeView}}
    """

  attachListeners:->

    activity    = @getData()
    commentList = @getDelegate()

    events =
      BackgroundActivityStarted  : 'show'
      BackgroundActivityFinished : 'hide'

    for ev, func of events
      commentList.off ev
      commentList.on ev, @loader.bound func

    @commentLink.on "click", (event)=>
      commentList.emit "CommentLinkReceivedClick", event, @

class ActivityActionLink extends KDCustomHTMLView
  constructor:(options,data)->
    options = $.extend
      tagName   : "a"
      cssClass  : "action-link"
      attributes:
        href    : "#"
      partial   : "Like"
    , options
    super options,data

class ActivityCountLink extends KDCustomHTMLView
  constructor:(options,data)->
    options = $.extend
      tagName   : "a"
      cssClass  : "count"
      attributes:
        href    : "#"
    , options
    super options,data

  render:->
    super
    @setCount @getData()

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    activity = @getData()
    @setCount activity

  pistachio:-> ""

class ActivityLikeCount extends ActivityCountLink

  @oldCount = 0

  setCount:(activity)->
    if activity.meta.likes isnt @oldCount
      @emit "countChanged", activity.meta.likes
    @oldCount = activity.meta.likes
    if activity.meta.likes is 0 then @hide() else @show()

  pistachio:-> "{{ #(meta.likes)}}"

class ActivityCommentCount extends ActivityCountLink

  setCount:(activity)->
    if activity.repliesCount is 0 then @hide() else @show()
    @emit "countChanged", activity.repliesCount

  pistachio:-> "{{ #(repliesCount)}}"

class ActivityOpinionCount extends ActivityCountLink

  setCount:(activity)->
    if activity.opinionCount is 0 then @hide() else @show()
    @emit "countChanged", activity.opinionCount

  pistachio:-> "{{ #(opinionCount)}}"
