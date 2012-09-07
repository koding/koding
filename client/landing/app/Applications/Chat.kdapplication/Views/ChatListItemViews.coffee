TOPICREGEX = /[#|@]([\w-]+)/g

class ChatListItemView extends KDListItemView
  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    parsedBody = @getData().body.replace(TOPICREGEX, "<a class='open-new-chat' href='#'>$&</a>")
    parsedChannel = @getData().channel?.replace(TOPICREGEX, "<a class='open-new-chat' href='#'>$&</a>")

    """
    <div class='meta'>      
      <span class='time'>[{{#(meta.createdAt)}}] </span>
      #{if @getData().channel? then "<span>[#{parsedChannel}]</span>" else ''}
      <span class="author-wrapper">{{#(author)}}: </span>
      <span>#{parsedBody}</span>
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