class PrivateMessageListItemView extends ActivityListItemView

  constructor: (options = {}, data) ->

    options.cssClass           = KD.utils.curry 'privatemessage ', options.cssClass
    options.commentViewClass or= ReplyView

    super options, data

    @likeView = new CommentLikeView {}, data

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
      {{> @avatar}}
      <div class='meta clearfix'>
        {{> @author}}
        {{> @timeAgoView}}
      </div>
      {{> @editWidgetWrapper}}
      {article{@formatContent #(body)}}
      {{> @embedBox}}
      {{> @likeView}}
    </div>
    {{> @commentBox}}
    """
