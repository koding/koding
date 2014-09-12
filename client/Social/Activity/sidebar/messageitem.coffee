class SidebarMessageItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item'
    options.route    = "Message/#{data.id}"

    super options, data

    @icon = new SidebarMessageItemIcon {}, data
    @text = new SidebarMessageItemText {}, data

    data.on 'ChannelDeleted', =>
      if location.pathname is "/Activity/Message/#{ data.getId() }"
        KD.singletons.router.clear()
      @getDelegate().removeItem this

  pistachio: ->
    "{{> @icon}}{{> @text}}{{> @unreadCount}}"


