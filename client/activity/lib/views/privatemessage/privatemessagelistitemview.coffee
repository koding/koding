kd = require 'kd'
ActivityListItemView = require '../activitylistitemview'
CommentTimeView = require '../comments/commenttimeview'
ReplyInputEditWidget = require './replyinputeditwidget'
ReplyLikeView = require '../replylikeview'
ReplyView = require '../comments/replyview'
formatContent = require 'app/util/formatContent'

module.exports = class PrivateMessageListItemView extends ActivityListItemView

  constructor: (options = {}, data) ->

    options.cssClass           = kd.utils.curry 'privatemessage ', options.cssClass
    options.editWidgetClass  or= ReplyInputEditWidget
    options.commentViewClass or= ReplyView
    options.commentSettings    = {}
    {commentSettings}          = options
    commentSettings.channelId  = options.channelId

    super options, data

    @decorate()

    {typeConstant, createdAt} = @getData()

    @likeView = new ReplyLikeView {}, @getData()
    @timeView = new CommentTimeView timeFormat : 'h:MM TT', createdAt

    @commentBox.listPreviousLink.on 'ReachedToTheBeginning', @bound 'showParentPost'

    @embedOptions  =
      hasDropdown : no
      delegate    : this
      type        : 'privatemessage'


  prepareDefaultBody: (type, addedBy) ->
    body = "has #{type} the chat"

    # append who added the user
    body = "#{body} from an invitation by @#{addedBy}" if addedBy

    return body


  prepareActivityMessage: ->

    {typeConstant, payload} = @getData()
    {addedBy, initialParticipants, activityType} = payload if payload
    typeConstant = activityType  if typeConstant is 'activity'

    # get default join/leave message body
    switch typeConstant
      when 'join'
        body = @prepareDefaultBody 'joined', addedBy  unless initialParticipants
      when 'leave'
        body = @prepareDefaultBody 'left', addedBy
      when 'invite'
        body = "invited to the session"
      when 'reject'
        body = "has rejected the invitation"
      else
        body = @getData().body


    # when it contains initial participants it contains all the accounts
    # initially added to the conversation
    if initialParticipants
      if initialParticipants.length is 0
        body = "started this conversation"
      else
        body = "started the conversation and invited "
        body = "#{body} @#{participant}," for participant in initialParticipants
        body = body.slice 0, body.length - 1

    return body


  decorate: ->

    {repliesCount, payload, typeConstant} = @getData()

    if typeConstant in ['join', 'leave', 'activity']
      @getData().body = @prepareActivityMessage()
      @setClass 'join-leave'

    if payload?['system-message'] or payload?['activityType']
      @setClass 'join-leave'

    @showParentPost()  if repliesCount < 3


  showParentPost: ->

    @setClass 'with-parent'
    firstReply = @commentBox.listController.getListItems().first

    return  unless firstReply

    if @getData().account._id is firstReply.getData().account._id
      firstReply.setClass 'consequent'



  hideParentPost: -> @unsetClass 'with-parent'


  pistachio: ->
    """
    <div class="activity-content-wrapper clearfix">
      {{> @settingsButton}}
      {{> @avatar}}
      <div class='meta clearfix'>
        {{> @author}} {{> @timeView }} {{> @likeView}}
      </div>
      {{> @editWidgetWrapper}}
      {article.has-markdown{formatContent #(body)}}
      {{> @embedBoxWrapper}}
    </div>
    """


