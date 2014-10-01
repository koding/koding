class PrivateMessageListItemView extends ActivityListItemView

  constructor: (options = {}, data) ->

    options.cssClass           = KD.utils.curry 'privatemessage ', options.cssClass
    options.commentViewClass or= ReplyView
    options.commentSettings    = {}
    {commentSettings}          = options
    commentSettings.channelId  = options.channelId
    options.activitySettings   = {}
    {activitySettings}         = options
    activitySettings.disableFollow ?= yes

    super options, data

    {typeConstant, payload, body} = data

    {addedBy} = payload if payload

    if typeConstant in ['join', 'leave']
      data.body = "has #{@prepareActivity()} the chat"

    data.body = "#{data.body} from an invitation by @#{addedBy}" if addedBy

    {createdAt, deletedAt, updatedAt} = data

    @likeView = new ReplyLikeView {}, data
    @timeView = new CommentTimeView {}, createdAt

    @decorate()

    @commentBox.listPreviousLink.on 'ReachedToTheBeginning', @bound 'showParentPost'

  prepareActivity: ->
    {typeConstant} = @getData()
    switch typeConstant
      when 'join'
        return 'joined'
      when 'leave'
        return 'left'

    return ''

  decorate: ->

    {repliesCount} = @getData()

    @showParentPost()  if repliesCount < 3


  showParentPost: ->

    @setClass 'with-parent'
    firstReply = @commentBox.controller.getListItems().first

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
        {{> @author}} {{> @timeView }} {{> @timeAgoView}} {{> @likeView}}
      </div>
      {{> @editWidgetWrapper}}
      {article.has-markdown{KD.utils.formatContent #(body)}}
      {{> @embedBox}}
    </div>
    """
