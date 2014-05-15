class CommentView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "comment-container", options.cssClass

    super options, data

    @header = new CommentViewHeader delegate: this, data

    @inputForm = new NewCommentForm delegate: this
      .on "Focused", @bound "decorateAsFocused"
      .on "Blured", @bound "resetDecoration"
      .on "Submit", @bound "reply"

    @controller = new CommentListViewController delegate: this, data
      .on "Mention", @inputForm.bound "mention"

    @forwardEvent @header, "AsyncJobStarted"
    @forwardEvent @header, "AsyncJobDone"


  reply: (body, callback = noop) ->

    activity = @getData()
    @emit "AsyncJobStarted"

    KD.singleton("appManager").tell "Activity", "reply", {activity, body}, (err, reply) =>

      @emit "AsyncJobFinished"

      return KD.showError err  if err

      if not KD.getSingleton('activityController').flags?.liveUpdates
        @addItem reply
        @emit "OwnCommentHasArrived"
      else
        @emit "OwnCommentWasSubmitted"

    KD.mixpanel "Comment activity, success"
    KD.getSingleton("badgeController").checkBadge
      property: "comments", relType: "commenter", source: "JNewStatusUpdate", targetSelf: 1


  decorateAsPassive: ->

    @unsetClass "active-comment"
    @setClass "no-comment"


  decorateAsActive: ->

    @unsetClass "no-comment"
    @setClass "commented"


  decorateAsFocused: ->

    @unsetClass "no-comment commented"
    @setClass   "active-comment"


  setFixedHeight: (maxHeight) ->

    @setClass "fixed-height"
    @controller.getView().$().css {maxHeight}


  resetDecoration: ->

    if @getData().repliesCount
    then @decorateAsActive()
    else @decorateAsPassive()


  viewAppended: ->

    super

    @setFixedHeight fixedHeight  if {fixedHeight} = @getOptions()

    @addSubView @header
    @addSubView @controller.getView()
    @addSubView @inputForm


  render: ->

    super

    @resetDecoration()
