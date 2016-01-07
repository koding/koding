whoami = require '../../util/whoami'
kd = require 'kd'
KDView = kd.View
JView = require '../../jview'
LeaveChannelButton = require './leavechannelbutton'
SidebarItem = require './sidebaritem'
SidebarMessageItemText = require './sidebarmessageitemtext'


module.exports = class SidebarMessageItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item'
    options.route    = "Message/#{data.id}"

    super options, data

    data.on 'ChannelDeleted', @bound 'channelDeleted'

    @text = new SidebarMessageItemText {}, data

    owner = data.creatorId is whoami().socialApiId

    @endButton = if owner
    then new LeaveChannelButton {}, data
    else new KDView


  channelDeleted: ->

    if global.location.pathname is @getOption 'route'
      kd.singletons.router.clear()

    @getDelegate().removeItem this


  click: (event) ->

    kd.utils.stopDOMEvent event
    kd.singleton('router').handleRoute @getOption 'route'

    super event


  pistachio: ->

    """
    {{> @text}}
    {{> @endButton}}
    {{> @unreadCount}}
    """
