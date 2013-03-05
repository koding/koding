class DiscussionActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @opinionCountLink  = new ActivityActionLink
      partial     : "Answer"
      click       : (event)=>
        event.preventDefault()
        @emit "DiscussionActivityLinkClicked"

    @commentCountLink  = new ActivityActionLink
      partial     : "Comment"
      click       : (event)=>
        event.preventDefault()
        @emit "DiscussionActivityCommentLinkClicked"

    if activity.opinionCount is 0
      @opinionCountLink.hide()

    @opinionCount = new ActivityOpinionCount
      tooltip     :
        title     : "Take me there!"
      click       : (event)=>
        event.preventDefault()
        @emit "DiscussionActivityLinkClicked"
    , activity

    @commentCount = new ActivityCommentCount
      tooltip     :
        title     : "Take me there!"
      click       : (event)=>
        event.preventDefault()
        @emit "DiscussionActivityCommentLinkClicked"
    , activity

    @opinionCount.on "countChanged", (count) =>
      if count > 0 then @opinionCountLink.show()
      else @opinionCountLink.hide()

    @on "DiscussionActivityLinkClicked", =>
      unless @parent instanceof ContentDisplayDiscussion
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()
      else
        @getDelegate().emit "OpinionLinkReceivedClick"

    @on "DiscussionActivityCommentLinkClicked", =>
      unless @parent instanceof ContentDisplayDiscussion
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()
        # KD.getSingleton("appManager").tell "Activity", "createContentDisplay", @getData()
      else
        @getDelegate().emit "CommentLinkReceivedClick"

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
      {{> @commentCountLink}} {{> @commentCount}} #{if @getData()?.repliesCount > 0 then " ·" else " ·" }
      <span class='optional'>
      {{> @shareLink}} ·
      </span>
      {{> @likeView}}
    """


class OpinionActivityActionsView extends ActivityActionsView

  constructor :->
    super

    activity = @getData()

    @commentLink  = new ActivityActionLink
      partial : "Comment"

    @commentCount?.destroy()

    @commentCount = new ActivityCommentCount
      tooltip     :
        title     : "Take me there!"
      click       : (event)=>
        event.preventDefault()
        @emit "DiscussionActivityLinkClicked"

    , activity

    @on "DiscussionActivityLinkClicked", =>
      unless @parent instanceof ContentDisplayDiscussion
        KD.getSingleton('router').handleRoute "/Activity/#{@getData().slug}", state:@getData()
        # KD.getSingleton("appManager").tell "Activity", "createContentDisplay", @getData()
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
    {{> @commentLink}}{{> @commentCount}}
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeView}}
    """


