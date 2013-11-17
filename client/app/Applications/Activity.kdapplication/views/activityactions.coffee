class ActivitySharePopup extends SharePopup

  constructor: (options={}, data)->

    options.cssClass        = "share-popup"
    options.shortenText     = true
    options.twitter         = @getTwitterOptions options
    options.newTab          = @getNewTabOptions options

    super options, data

  getTwitterOptions:(options)->
    data = options.delegate.getData()
    {tags} = data
    if tags
      hashTags  = ("##{tag.slug}"  for tag in tags when tag?.slug)
      hashTags  = _.unique(hashTags).join " "
      hashTags += " "
    else
      hashTags = ''

    {title, body} = data
    itemText  = KD.utils.shortenText title or body, maxLength: 100, minLength: 100
    shareText = "#{itemText} #{hashTags}- #{options.url}"

    return twitter =
      enabled : true
      text    : shareText

  getNewTabOptions:(options)->
    return { enabled : true, url : options.url }

class ActivityActionsView extends KDView

  contextMenu = null
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
      partial         : "Share"
      click           :(event)=>
        data = @getData()
        if data?.group? and data.group isnt "koding"
          shareUrl = "#{KD.config.mainUri}/#!/#{data.group}/Activity/#{data.slug}"
        else
          shareUrl      = "#{KD.config.mainUri}/#!/Activity/#{data.slug}"
        contextMenu   = new JContextMenu
          cssClass    : "activity-share-popup"
          type        : "activity-share"
          delegate    : this
          x           : @getX() - 35
          y           : @getY() - 50
          arrow       :
            placement : "bottom"
            margin    : 110
          lazyLoad    : yes
        , customView  : new ActivitySharePopup delegate: this, url: shareUrl

        new KDOverlayView
          parent      : KD.singletons.mainView.mainTabView.activePane
          transparent : yes

    @likeView     = new LikeView {}, activity
    @loader       = new KDLoaderView size : width : 14

    # unless KD.isLoggedIn()
    #   @commentLink.setTooltip title: "Login required"
    #   @likeView.likeLink.setTooltip title: "Login required"
    #   KD.getSingleton("mainController").on "accountChanged.to.loggedIn", =>
    #     delete @likeView.likeLink.tooltip
    #     delete @commentLink.tooltip

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
    <span class='logged-in'>
    {{> @commentLink}}{{> @commentCount}}
    </span>
    <i> · </i>
    <span class='optional'>
    {{> @shareLink}}
    </span>
    <i> · </i>
    <span class='logged-in'>
    {{> @likeView}}
    </span>
    """

  attachListeners:->

    activity    = @getData()
    commentList = @getDelegate()

    events =
      BackgroundActivityStarted  : 'show'
      BackgroundActivityFinished : 'hide'

    for own ev, func of events
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
