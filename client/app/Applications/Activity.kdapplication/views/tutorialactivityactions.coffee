class TutorialActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @opinionCountLink  = new ActivityActionLink
      partial     : "Opinions"
      click     : (event)=>
        event.preventDefault()
        @emit "TutorialActivityLinkClicked"

    if activity.opinionCount is 0 then @opinionCountLink.hide()

    @opinionCount = new ActivityOpinionCount
      click:(event)->
        event.preventDefault()
    , activity

    @opinionCount.on "countChanged", (count) =>
      if count > 0 then @opinionCountLink.show()
      else @opinionCountLink.hide()

    @on "TutorialActivityLinkClicked", =>
      unless @parent instanceof ContentDisplayTutorial
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()
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
      {{> @opinionCountLink}} {{> @opinionCount}} #{if @getData()?.opinionCount > 0 then " ·" else "" }
      <span class='optional'>
      {{> @shareLink}} ·
      </span>
      {{> @likeView}}
    """