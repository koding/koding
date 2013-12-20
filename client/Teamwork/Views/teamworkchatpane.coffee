class TeamworkChatPane extends ChatPane

  constructor: (options = {}, data) ->

    super options, data

    @setClass "tw-chat"
    @getDelegate().setClass "tw-chat-open"

  createDock: ->
    @dock = new KDCustomHTMLView cssClass: "hidden"

  updateCount: ->