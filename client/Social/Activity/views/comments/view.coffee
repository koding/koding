class CommentView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = KD.utils.curry 'comment-container', options.cssClass
    options.controllerClass   or= CommentListViewController

    super options, data

    @fakeMessageMap = {}

    @inputForm = new CommentInputForm delegate: this
      .on 'Focused', @bound 'decorateAsFocused'
      .on 'Blured',  @bound 'resetDecoration'
      .on 'SubmitStarted',  @bound 'handleEnter'
      .on 'SubmitStarted',  @bound 'reply'

    {controllerClass} = @getOptions()

    @controller = new controllerClass delegate: this, data
      .on 'Mention', @inputForm.bound 'mention'

    @listPreviousLink = new CommentListPreviousLink
      delegate : @controller
      click    : @bound 'listPreviousReplies'
    , data

    @on 'Reply', @inputForm.bound 'setFocus'

    @on 'CommentSavedSuccessfully', @bound 'replaceFakeItemView'

    data
      .on 'AddReply', @bound 'addMessage'
      .on 'RemoveReply', @controller.lazyBound 'removeItem', null


  addMessage: (message) ->

    return  if message.account._id is KD.whoami()._id

    @controller.addItem message


  handleEnter: (value, clientRequestId) ->
    return  unless value

    @createFakeItemView value, clientRequestId


  putMessage: (message) -> @controller.addItem message


  createFakeItemView: (value, clientRequestId) ->

    fakeData = KD.utils.generateDummyMessage value

    item = @putMessage fakeData

    # save it to a map so that we have a reference
    # to it to be deleted.
    @fakeMessageMap[clientRequestId] = item


  replaceFakeItemView: (message) ->

    @putMessage message

    @removeFakeMessage message.clientRequestId


  removeFakeMessage: (identifier) ->

    return  unless item = @fakeMessageMap[identifier]

    @controller.removeItem item


  listPreviousReplies: (event) ->

    KD.utils.stopDOMEvent event

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

      @controller.addItem reply, index for reply, index in replies
      @listPreviousLink.update()


  reply: (value, clientRequestId) ->

    activity        = @getData()
    {appManager}    = KD.singletons
    body            = value

    appManager.tell 'Activity', 'reply', {activity, body, clientRequestId}, (err, reply) =>

      return KD.showError err  if err

      @emit 'CommentSavedSuccessfully', reply

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
