class TutorialActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @opinionCount?.destroy()

    @opinionCountLink  = new ActivityActionLink
      partial     : "Opinions"
      click     : (pubInst, event)=>
        @emit "TutorialActivityLinkClicked"

    if activity.repliesCount is 0 then @opinionCountLink.hide()

    @opinionCount = new ActivityCommentCount {}, activity

    @opinionCount.on "countChanged", (count) =>
      if count > 0 then @opinionCountLink.show()
      else @opinionCountLink.hide()

    @on "TutorialActivityLinkClicked", =>
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
      {{> @opinionCountLink}} {{> @opinionCount}} #{if @getData()?.repliesCount > 0 then " ·" else "" }
      <span class='optional'>
      {{> @shareLink}} ·
      </span>
      {{> @likeView}}
    """