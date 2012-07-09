class ActivityActionsView extends KDView
  constructor:->
    super
    activity = @getData()
    @commentLink  = new ActivityActionLink    {partial : "Comment"}
    @commentCount = new ActivityCommentCount  {}, activity
    @shareLink    = new ActivityActionLink
      partial     : "Share"
      tooltip     :
        title     : "<p class='login-tip'>Coming Soon</p>"
        placement : "above"
        offset    : 3

    @likeCount    = new ActivityLikeCount     {}, activity
    @likeLink     = new ActivityActionLink
      partial     : "Like"
      ###
      tooltip     :
        title     : if @likeCount.getData() in [0, null] then "Be first" else "Hope"
        placement : "above"
        offset    : 3
      ###

    @loader       = new KDLoaderView          size : width : 14

  viewAppended:->
    @setClass "activity-actions"
    @setTemplate @pistachio()
    @template.update()
    @attachListeners()
    @loader.hide()

  pistachio:->
    tmpl =
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
          # oldCount = @likeCount.data.meta.likes
          activity.like (err)=>
            # log arguments, 'you like me!'
            if err
              new KDNotificationView
                title     : "You already liked this!"
                duration  : 1300
            # FIXME Implement Unlike behaviour
            ###
            newCount = @likeCount.data.meta.likes
            if oldCount < newCount then @likeLink.updatePartial("Unlike")
            else @likeLink.updatePartial("Like")
            ###

    @commentLink.registerListener
      KDEventTypes  : "Click"
      listener      : @
      callback      : ->
        commentList.propagateEvent KDEventType : "CommentLinkReceivedClick"

class ActivityActionLink extends KDCustomHTMLView
  constructor:(options,data)->
    options = $.extend
      tagName   : "a"
      cssClass  : "action-link"
      attributes:
        href    : "#"
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
    # log "Like Count: " + activity.meta.likes
    if activity.meta.likes == 0 then @hide() else @show()

  pistachio:-> "{{ #(meta.likes)}}"

class ActivityCommentCount extends ActivityCountLink

  setCount:(activity)->
    if activity.repliesCount is 0 then @hide() else @show()

  pistachio:-> "{{ #(repliesCount)}}"
