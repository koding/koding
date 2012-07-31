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

    @likeCount    = new ActivityLikeCount
      tooltip     :
        title     : ""
        engine    : "tipsy" # We should force to use tipsy because
                            # for now only tipsy supports tooltip updates
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        if activity.meta.likes > 0 # 3
          activity.fetchLikedByes {},
            sort  : timestamp : -1
            , (err, likes) =>
              new FollowedModalView {title:"Members who liked " + activity.body}, likes
      , activity

    @likeCount.on "countChanged", (count) =>
      @updateLikeState(yes)

    @likeLink     = new ActivityActionLink
    @loader       = new KDLoaderView size : width : 14

  updateLikeState:(checkIfILiked = no)->

    activity = @likeCount.getData()
    return if activity.meta.likes is 0

    activity.fetchLikedByes {},
      limit : if checkIfILiked then activity.meta.likes else 3
      sort  : timestamp : -1

      , (err, likes) =>

        peopleWhoLiked   = []

        if likes
          if checkIfILiked
            {_id}       = KD.whoami()
            likedBefore = likes.filter((item)-> item._id is _id).length > 0

          likes.forEach (item)=>
            if peopleWhoLiked.length < 3
              {firstName, lastName} = item.profile
              peopleWhoLiked.push "<strong>" + firstName + " " + lastName + "</strong>"
            else return

          # switch activity.meta.likes
          #   when 0 then tooltip = ""
          #   when 1 then tooltip = "{{> @peopleWhoLiked0}}"
          #   when 2 then tooltip = "{{> @peopleWhoLiked0}} and {{> @peopleWhoLiked1}}"
          #   when 3 then tooltip = "{{> @peopleWhoLiked0}}, {{> @peopleWhoLiked1}} and {{> @peopleWhoLiked2}}"
          #   else        tooltip = "{{> @peopleWhoLiked0}}, {{> @peopleWhoLiked1}}, {{> @peopleWhoLiked2}} and {{activity.meta.likes - 3}} more."

          if activity.meta.likes is 1
            tooltip = peopleWhoLiked[0]
          else if activity.meta.likes is 2
            tooltip = peopleWhoLiked[0] + " and " + peopleWhoLiked[1]
          else if activity.meta.likes is 3
            tooltip = peopleWhoLiked[0] + ", " + peopleWhoLiked[1] + " and " + peopleWhoLiked[2]
          else
            tooltip = peopleWhoLiked[0] + ", " + peopleWhoLiked[1] + " and <strong>" + (activity.meta.likes - 2) + " more.</strong>"

          @likeCount.updateTooltip {title: tooltip }

          # if checkIfILiked
          #   @likeLink.updatePartial if likedBefore then "Unlike" else "Like"

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

  @oldCount = 0

  setCount:(activity)->
    if activity.meta.likes isnt @oldCount
      @emit "countChanged", activity.meta.likes
    @oldCount = activity.meta.likes
    if activity.meta.likes == 0 then @hide() else @show()

  pistachio:-> "{{ #(meta.likes)}}"

class ActivityCommentCount extends ActivityCountLink

  setCount:(activity)->
    if activity.repliesCount is 0 then @hide() else @show()

  pistachio:-> "{{ #(repliesCount)}}"
