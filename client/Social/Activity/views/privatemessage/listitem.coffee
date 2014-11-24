class PrivateMessageListItemView extends ActivityListItemView

  constructor: (options = {}, data) ->

    options.cssClass           = KD.utils.curry 'privatemessage ', options.cssClass
    options.editWidgetClass  or= ReplyInputEditWidget
    options.commentViewClass or= ReplyView
    options.commentSettings    = {}
    {commentSettings}          = options
    commentSettings.channelId  = options.channelId

    super options, data

    {typeConstant} = @getData()
    @decorate()


    {createdAt, deletedAt, updatedAt} = data

    @likeView = new ReplyLikeView {}, data
    @timeView = new CommentTimeView timeFormat : 'h:MM TT', createdAt

    @commentBox.listPreviousLink.on 'ReachedToTheBeginning', @bound 'showParentPost'


  prepareDefaultBody: (type) -> "has #{type} the chat"


  prepareActivityMessage: ->

    {typeConstant, payload} = @getData()
    {addedBy, initialParticipants} = payload if payload

    # get default join/leave message body
    switch typeConstant
      when 'join'
        body = @prepareDefaultBody 'joined'  unless initialParticipants
      when 'leave'
        body = @prepareDefaultBody 'left'

    # append who added the user
    body = "#{body} from an invitation by @#{addedBy}" if addedBy

    # when it contains initial participants it contains all the accounts
    # initially added to the conversation
    if initialParticipants?.length
      if initialParticipants.length is 1
        body = "started this conversation"
      else
        body = "started the conversation and invited "
        body = "#{body} @#{participant}," for participant in initialParticipants
        body = body.slice 0, body.length - 1

    return body


  decorate: ->

    {repliesCount, payload, typeConstant} = @getData()

    if typeConstant in ['join', 'leave']
      @getData().body = @prepareActivityMessage()
      @setClass 'join-leave'

    if payload?['system-message']
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
      {article.has-markdown{KD.utils.formatContent #(body)}}
      {{> @embedBox}}
    </div>
    """
