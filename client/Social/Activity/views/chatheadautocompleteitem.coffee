class ChatHead extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options, data) ->

    options.cssClass = 'chat-head'

    super options, data


  viewAppended: ->

    account = @getData()

    { profile: { firstName } } = account

    @addSubView new AvatarStaticView
      size      :
        width   : 30
        height  : 30
    , account

    @addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'first-name'
      partial  : firstName


  click: KDAutoCompletedItem::click

