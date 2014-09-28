class CommentView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = KD.utils.curry 'comment-container', options.cssClass
    options.controllerClass   or= CommentListViewController

    super options, data

    @fakeMessageMap = {}

    @createInputWidget()
    @bindInputEvents()

    {controllerClass} = @getOptions()

    @controller = new controllerClass delegate: this, data

    @listPreviousLink = new CommentListPreviousLink
      delegate : @controller
      click    : @bound 'listPreviousReplies'
    , data

    @on 'Reply', @input.bound 'setFocus'

    @bindMentionEvents()
    @bindDataEvents()


  bindMentionEvents: ->

    @on 'MentionHappened', @input.bound 'mention'

    @on 'MouseEnterHappenedOnMention', (item) =>
      @input.disableSetPlaceholder()

    @on 'MouseLeaveHappenedOnMention', (item) =>
      @input.enableSetPlaceholder()


  bindDataEvents: ->
    data = @getData()

    data
      .on 'AddReply',    @bound 'addMessage'
      .on 'RemoveReply', @controller.lazyBound 'removeItem', null


  createInputWidget: ->

    activity = @getData()

    @input = new CommentInputWidget {activity}


  bindInputEvents: ->

    return  unless @input

    @input
      .on 'Focused',         @bound 'decorateAsFocused'
      .on 'Blured',          @bound 'resetDecoration'
      .on 'SubmitStarted',   @bound 'handleEnter'
      .on 'SubmitSucceeded', @bound 'replaceFakeItemView'
      .on 'SubmitFailed',    @bound 'messageSubmitFailed'


  addMessage: (message) ->

    return  if message.account._id is KD.whoami()._id

    @controller.addItem message


  handleEnter: (value, clientRequestId) ->

    return  unless value

    @input.reset yes

    @createFakeItemView value, clientRequestId


  putMessage: (message, index) ->

    @controller.addItem message, index or @controller.getItemCount()


  createFakeItemView: (value, clientRequestId) ->

    fakeData = KD.utils.generateDummyMessage value

    item = @putMessage fakeData

    # save it to a map so that we have a reference
    # to it to be deleted.
    @fakeMessageMap[clientRequestId] = item


  replaceFakeItemView: (message) ->

    @putMessage message, @removeFakeMessage message.clientRequestId


  removeFakeMessage: (identifier) ->

    return  unless item = @fakeMessageMap[identifier]

    index = @controller.getListView().getItemIndex item

    @controller.removeItem item

    return index


  messageSubmitFailed: (err, clientRequestId) ->
    view = @fakeMessageMap[clientRequestId]
    view.showResend()
    view.on 'SubmitSucceeded', (comment) =>
      comment.clientRequestId = clientRequestId
      @replaceFakeItemView comment


  listPreviousReplies: (event) ->

    KD.utils.stopDOMEvent event

    @emit 'AsyncJobStarted'

    {appManager} = KD.singletons
    activity     = @getData()
    from         = activity.replies.first.createdAt
    limit        = 10

    appManager.tell 'Activity', 'listReplies', {activity, from, limit}, (err, replies) =>

      @emit 'AsyncJobFinished'

      return KD.showError err  if err

      replies.reverse()

      activity.replies = replies.concat activity.replies

      @controller.addItem reply, index for reply, index in replies
      @listPreviousLink.update()


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
    @addSubView @input


  render: ->

    super

    @resetDecoration()

