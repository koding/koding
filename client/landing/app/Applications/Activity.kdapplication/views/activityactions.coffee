class ActivityActionsView extends KDView

  constructor:->

    super

    activity = @getData()
    @commentLink  = new ActivityActionLink
      partial : "Comment"
    @commentCount = new ActivityCommentCount
      tooltip     :
        title     : "Show all"
      click       : =>
        @getDelegate().emit "CommentCountClicked"
    , activity
    @shareLink    = new ActivityActionLink
      partial     : "Share"
      tooltip     :
        title     : "<p class='login-tip'>Coming Soon</p>"
        placement : "above"
        offset    : 3

    @likeCount    = new ActivityLikeCount {}, activity
    @likeLink     = new ActivityActionLink

    @updateLikeState()

    @loader       = new KDLoaderView size : width : 14

  updateLikeState:->
    {_id}   = KD.whoami()
    activity = @likeCount.getData()
    activity.fetchLikedByes (err, likes) =>
      likedBefore  = no
      peopleWhoLiked = []

      if KD.isLoggedIn() and likes
        likes.forEach (item)=>
          likedBefore = if item._id is _id then yes

          {firstName, lastName} = item.profile
          peopleWhoLiked.push firstName + " " + lastName

      # log "Tooltip:", peopleWhoLiked, likedBefore, @getData()
      @likeCount.setTooltip {title: peopleWhoLiked.join ", " }
      # @likeLink.updatePartial if likedBefore then "Unlike" else "Like"

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
    {{> @likeLink}}{{> @likeCount}}
    """

  attachListeners:->

    activity    = @getData()
    commentList = @getDelegate()

    commentList.on "BackgroundActivityStarted", => @loader.show()
    commentList.on "BackgroundActivityFinished", => @loader.hide()
    @likeLink.registerListener
      KDEventTypes  : "Click"
      listener      : @
      callback      : =>
        if KD.isLoggedIn()
          activity.like (err)=>
            if err
              log "Something went wrong while like:", err
              new KDNotificationView
                title     : "You already liked this!"
                duration  : 1300 
            else
              @updateLikeState()

    @commentLink.registerListener
      KDEventTypes  : "Click"
      listener      : @
      callback      : (pubInst, event) ->
        commentList.propagateEvent KDEventType : "CommentLinkReceivedClick", event

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

  setCount:(activity)->
    # log "ACTIVITY: ", activity
    if activity.meta.likes == 0 then @hide() else @show()

  pistachio:-> "{{ #(meta.likes)}}"

class ActivityCommentCount extends ActivityCountLink

  setCount:(activity)->
    if activity.repliesCount is 0 then @hide() else @show()

  pistachio:-> "{{ #(repliesCount)}}"
