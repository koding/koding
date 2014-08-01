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

    @likeView = new ReplyLikeView {}, data

    @decorate()

    @commentBox.listPreviousLink.on 'ReachedToTheBeginning', @bound 'showParentPost'


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
        {{> @author}}{{> @timeAgoView}}{{> @likeView}}
      </div>
      {{> @editWidgetWrapper}}
      {article{@formatContent #(body)}}
      {{> @embedBox}}
    </div>
    """
