class DiscussionActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @opinionLink = new ActivityActionLink
      partial   : "Join this discussion"
      click     : (pubInst, event)=>
        @emit "DiscussionActivityLinkClicked"

    @opinionCount?.destroy()

    @opinionCount = new ActivityCommentCount
      tooltip     :
        title     : "Take me there!"
      click       : (pubInst, event)=>
        @emit "DiscussionActivityLinkClicked"
    , activity

    @on "DiscussionActivityLinkClicked", =>
      unless @parent instanceof ContentDisplayDiscussion
        appManager.tell "Activity", "createContentDisplay", @getData()
      else
        @getDelegate().emit "OpinionLinkReceivedClick"

  viewAppended:->
    @setClass "activity-actions"
    @setTemplate @pistachio()
    @template.update()
    @attachListeners()
    @loader.hide()

  attachListeners:->
    activity    = @getData()
    opinionList = @getDelegate()

    opinionList.on "BackgroundActivityStarted", => @loader.show()
    opinionList.on "BackgroundActivityFinished", => @loader.hide()

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

  pistachio:->
    """
    {{> @loader}}
    {{> @opinionLink}}{{> @opinionCount}} ·
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeLink}}{{> @likeCount}}
    """