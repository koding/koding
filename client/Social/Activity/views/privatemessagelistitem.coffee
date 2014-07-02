class PrivateMessageListItemView extends ActivityListItemView

  constructor:(options = {},data)->
    options.cssClass = KD.utils.curry 'privatemessage ', options.cssClass

    super options, data

    @likeView    = new CommentLikeView {}, data

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
