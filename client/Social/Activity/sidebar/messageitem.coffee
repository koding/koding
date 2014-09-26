class SidebarMessageItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item'
    options.route    = "Message/#{data.id}"

    super options, data

    data.on 'ChannelDeleted', @bound 'channelDeleted'

    @icon = new SidebarMessageItemIcon {}, data
    @text = new SidebarMessageItemText {}, data

  channelDeleted: ->

    if location.pathname is "/#{@getOption 'route'}"
      KD.singletons.router.clear()

    @getDelegate().removeItem this


  pistachio: ->
    "{{> @icon}}{{> @text}}{{> @unreadCount}}"


