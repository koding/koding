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

    owner = data.creatorId is KD.whoami().socialApiId

    @endButton = if owner
    then new LeaveChannelButton {}, data
    else KDView


  channelDeleted: ->

    if location.pathname is "/#{@getOption 'route'}"
      KD.singletons.router.clear()

    @getDelegate().removeItem this


  click: (event) ->

    KD.utils.stopDOMEvent event
    KD.singleton('router').handleRoute "/#{@getOption 'route'}"

    super event


  pistachio: ->

    """
    {{> @icon}}
    {{> @text}}
    {{> @endButton}}
    {{> @unreadCount}}
    """
