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


  prepareDefaultBody: (options = {}) ->

    { addedBy, paneType, initialParticipants, action } = options

    # when it contains initial participants it contains all the accounts
    # initially added to the conversation
    if initialParticipants
      body = "has started the #{paneType}"

      return body  if initialParticipants.length is 0

      body = "#{body} and invited "
      body = "#{body} @#{participant}," for participant in initialParticipants

      return body.slice 0, body.length - 1

    body = "has #{action} the #{paneType}"

    # append who added the user
    body = "#{body} from an invitation by @#{addedBy}"  if addedBy

    return body


  prepareActivityMessage: ->

    { typeConstant, payload } = @getData()

    { channelType } = @getOptions()

    {addedBy, initialParticipants, systemType} = payload if payload
    typeConstant = systemType  if typeConstant is 'system'

    paneType = if channelType is 'privatemessage' then 'conversation' else 'session'

    options = { addedBy, paneType, initialParticipants }

    # get default join/leave message body
    switch typeConstant
      when 'join'
        options.action = 'joined'
        body = @prepareDefaultBody options
      when 'leave'
        options.action = 'left'
        body = @prepareDefaultBody options
      when 'invite'
        body = "was invited to the #{paneType}"
      when 'reject'
        body = "has rejected the invite for this #{paneType}"
      when 'kick'
        body = "has been removed from this #{paneType}"
      when 'initiate'
        body = @prepareDefaultBody options
      else
        body = @getData().body

    return body


  decorate: ->

    {repliesCount, payload, typeConstant} = @getData()

    if typeConstant in ['join', 'leave', 'system']
      @getData().body = @prepareActivityMessage()
      @setClass 'join-leave'

    if payload?['system-message'] or payload?['system']
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
