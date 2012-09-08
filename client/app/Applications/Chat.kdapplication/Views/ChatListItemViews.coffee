TOPICREGEX = /[#|@]([\w-]+)/g

class ChatListItemView extends KDListItemView
  constructor: (options, data) ->
    super
    {author} = data
    @avatar = new AvatarView {},author
    @profileText = new ProfileLinkView {shouldShowNick: yes},author

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    parsedBody = @getData().body.replace(TOPICREGEX, "<a class='open-new-chat' href='#'>$&</a>")
    parsedChannel = @getData().channel?.replace(TOPICREGEX, "<a class='open-new-chat' href='#'>$&</a>")

    """
    <div class='meta'>
      #{if @getData().channel? then "<span>[#{parsedChannel}]</span>" else ''}
      <span class='avatar'>{{> @avatar}}</span>
      <span class="author-wrapper fl">{{> @profileText}}</span>
      <span class='time fr'>[{{#(meta.createdAt)}}] </span><br />
      <span>#{parsedBody}</span>
      <hr>
    </div>
    """

class ChannelListItemView extends KDListItemView
  constructor: (options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    options.bind     = "contextmenu"
    super
    @avatar = new AvatarView {size : width : 16, height : 16},data
    @profileText = new ProfileTextView {shouldShowNick: yes},data

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    """
      <span class='avatar'>{{> @avatar}}</span>
      {{> @profileText}} (@#{@getData().profile.nickname})
    """