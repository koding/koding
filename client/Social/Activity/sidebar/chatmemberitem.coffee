class SidebarChatMemberItem extends SidebarMemberItem

  constructor: (options = {}, data) ->

    options.hideLastMessage      ?= yes
    options.hideNewMessageCount  ?= yes

    super options, data

    status = @getData().onlineStatus or "offline"

    @statusIndicator = new KDCustomHTMLView
      cssClass  : "online-status #{status}"

  viewAppended:->
    super

    @addSubView @statusIndicator
