kd = require 'kd'
KDView = kd.View
CommentInputWidget = require './commentinputwidget'
CommentListPreviousLink = require './commentlistpreviouslink'
CommentListViewController = require './commentlistviewcontroller'
showError = require 'app/util/showError'
generateDummyMessage = require 'app/util/generateDummyMessage'
isElementInViewport = require 'app/util/isElementInViewport'
Encoder = require 'htmlencode'


module.exports = class CommentView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = kd.utils.curry 'comment-container', options.cssClass
    options.controllerClass   or= CommentListViewController

    super options, data

    @fakeMessageMap = {}

    @createInputWidget()
    @bindInputEvents()

    {controllerClass} = @getOptions()

    @listController = new controllerClass delegate: this, data

    @listPreviousLink = new CommentListPreviousLink
      delegate : @listController
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
      .on 'RemoveReply', @bound 'removeMessage'


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


  addMessage: (message) -> @listController.addItem message


  removeMessage: (reply) ->

    MessagePane = require '../messagepane'
    MessagePane::removeMessage.call this, reply


  handleEnter: (value, clientRequestId) ->

    return  unless value

    value = Encoder.XSSEncode value

    @input.reset yes

    @createFakeItemView value, clientRequestId


  putMessage: (message, index) ->

    @listController.addItem message, index or @listController.getItemCount()


  createFakeItemView: (value, clientRequestId) ->

    fakeData = generateDummyMessage value

    item = @putMessage fakeData

    # save it to a map so that we have a reference
    # to it to be deleted.
    @fakeMessageMap[clientRequestId] = item


  replaceFakeItemView: (message) ->

    activity = @getData()

    @putMessage message, @removeFakeMessage message.clientRequestId

    @addMessageReply activity, message


  addMessageReply: require 'activity/mixins/addmessagereply'


  removeFakeMessage: (identifier) ->

    return  unless item = @fakeMessageMap[identifier]

    index = @listController.getListView().getItemIndex item

    @listController.removeItem item

    return index


  messageSubmitFailed: (err, clientRequestId) ->
    view = @fakeMessageMap[clientRequestId]
    view.showResend()
    view.on 'SubmitSucceeded', (comment) =>
      comment.clientRequestId = clientRequestId
      @replaceFakeItemView comment


  listPreviousReplies: (event) ->

    kd.utils.stopDOMEvent event

    @emit 'AsyncJobStarted'

    {appManager} = kd.singletons
    activity     = @getData()
    from         = activity.replies.first.createdAt
    limit        = 10

    appManager.tell 'Activity', 'listReplies', {activity, from, limit}, (err, replies) =>

      @emit 'AsyncJobFinished'

      return showError err  if err

      replies.reverse()

      activity.replies = replies.concat activity.replies

      @listController.addItem reply, index for reply, index in replies
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

    isInViewPort = isElementInViewport element = @getElement()

    element.scrollIntoView no  unless isInViewPort


  setFixedHeight: (maxHeight) ->

    @setClass 'fixed-height'
    @listController.getView().$().css {maxHeight}


  resetDecoration: ->

    if @getData().repliesCount
    then @decorateAsActive()
    else @decorateAsPassive()


  viewAppended: ->

    super

    @setFixedHeight fixedHeight  if {fixedHeight} = @getOptions()

    @addSubView @listPreviousLink
    @addSubView @listController.getView()
    @addSubView @input


  render: ->

    super

    @resetDecoration()
