class TutorialActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @opinionCount?.destroy()

    @opinionCountLink  = new ActivityActionLink
      partial     : "Opinions"
      click     : (pubInst, event)=>
        @emit "DiscussionActivityLinkClicked"

    if activity.repliesCount is 0 then @opinionCountLink.hide()

    @opinionCount = new ActivityCommentCount
      tooltip     :
        title     : "Take me there!"
      click       : (pubInst, event)=>
        @emit "DiscussionActivityLinkClicked"
    , activity

    @opinionCount.on "countChanged", (count) =>
      if count > 0 then @opinionCountLink.show()
      else @opinionCountLink.hide()

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

  pistachio:->
    """
    {{> @loader}}
    {{> @opinionCountLink}} {{> @opinionCount}}
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeView}}
    """