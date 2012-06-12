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
      
    @likeLink     = new ActivityActionLink    {partial : "Like" }
    @likeCount    = new ActivityLikeCount     {}, activity
    @loader       = new KDLoaderView          size : width : 14 
    
    @deleteBtn    = new ActivityActionLink    {partial : "Delete" }
  
  viewAppended:->
    @setClass "activity-actions"
    @setTemplate @pistachio()
    @template.update()
    @attachListeners()
    @loader.hide()

  pistachio:->
    """
    {{> @deleteBtn}}
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

    commentList.registerListener
      KDEventTypes  : "BackgroundActivityStarted"
      listener      : @
      callback      : => @loader.show()

    commentList.registerListener
      KDEventTypes  : "BackgroundActivityFinished"
      listener      : @
      callback      : => @loader.hide()
      
    @likeLink.registerListener
      KDEventTypes  : "Click"      
      listener      : @
      callback      : ->
        if @getSingleton('mainController').isUserLoggedIn()
          activity.like (err)-> log arguments, 'you like me!'
    
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
    if activity.meta.likes is 0 then @hide() else @show()

  pistachio:-> "{{ #(meta.likes)}}"

  
class ActivityCommentCount extends ActivityCountLink

  setCount:(activity)->
    if activity.repliesCount is 0 then @hide() else @show()

  pistachio:-> "{{ #(repliesCount)}}"
