class DiscussionActivityActionsView extends ActivityActionsView
  constructor :->
    super

    activity = @getData()

    @opinionLink = new ActivityActionLink
      partial   : "Join this discussion"
      click     : (pubInst, event)=>

        # as an item, in the activity feed, this should link to the ContenD
        unless @parent instanceof ContentDisplayDiscussion
          appManager.tell "Activity", "createContentDisplay", @getData()



    @opinionCount?.destroy()

    @opinionCount = new ActivityCommentCount
      tooltip     :
        title     : "Show all"
    , activity

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