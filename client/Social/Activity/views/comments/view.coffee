class CommentView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = KD.utils.curry 'comment-container', options.cssClass
    options.controllerClass   or= CommentListViewController

    super options, data

    @inputForm = new CommentInputForm delegate: this
      .on 'Focused', @bound 'decorateAsFocused'
      .on 'Blured',  @bound 'resetDecoration'
      .on 'Submit',  @bound 'reply'

    {controllerClass} = @getOptions()

    @controller = new controllerClass delegate: this, data
      .on 'Mention', @inputForm.bound 'mention'

    @listPreviousLink = new CommentListPreviousLink
      delegate : @controller
      click    : @bound 'listPreviousReplies'
    , data

    @on 'Reply', @inputForm.bound 'setFocus'

    data
      .on 'AddReply', @controller.bound 'addItem'
      .on 'RemoveReply', @controller.lazyBound 'removeItem', null


  listPreviousReplies: ->

    @emit 'AsyncJobStarted'

    {appManager} = KD.singletons
    activity     = @getData()
    from         = activity.replies[0].meta.createdAt.toISOString()
    limit        = 10

    appManager.tell 'Activity', 'listReplies', {activity, from, limit}, (err, replies) =>

      @emit 'AsyncJobFinished'

      return KD.showError err  if err

      replies.reverse()

      activity.replies = replies.concat activity.replies

      @emit 'ReachedToTheBeginning'
      @controller.addItem reply, index for reply, index in replies
      @listPreviousLink.update()


  reply: (body, callback = noop) ->

    activity     = @getData()
    {appManager} = KD.singletons

    appManager.tell 'Activity', 'reply', {activity, body}, (err, reply) =>

      return KD.showError err  if err

      KD.mixpanel 'Comment activity, success'

  decorateAsPassive: ->

    @unsetClass 'active-comment'
    @setClass 'no-comment'


  decorateAsActive: ->

    @unsetClass 'no-comment'
    @setClass 'commented'


  decorateAsFocused: ->

    @unsetClass 'no-comment commented'
    @setClass   'active-comment'


  setFixedHeight: (maxHeight) ->

    @setClass 'fixed-height'
    @controller.getView().$().css {maxHeight}


  resetDecoration: ->

    if @getData().repliesCount
    then @decorateAsActive()
    else @decorateAsPassive()


  viewAppended: ->

    super

    @setFixedHeight fixedHeight  if {fixedHeight} = @getOptions()

    @addSubView @listPreviousLink
    @addSubView @controller.getView()
    @addSubView @inputForm


  render: ->

    super

    @resetDecoration()
