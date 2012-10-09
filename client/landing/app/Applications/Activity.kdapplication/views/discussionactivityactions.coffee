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

  pistachio:->
    """
    {{> @loader}}
    {{> @opinionLink}} · {{> @opinionCount}} <span class="activity-text">#{if @getData().repliesCount is 0 then "No " else ""}answers</span> ·
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeView}}
    """


class OpinionActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @commentCount?.destroy()

    @commentCount = new ActivityCommentCount
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

  pistachio:->
    """
    {{> @loader}}
    {{> @commentCount}} <span class="activity-text">#{if @getData().repliesCount is 0 then "No " else ""}comments</span> ·
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeView}}
    """


