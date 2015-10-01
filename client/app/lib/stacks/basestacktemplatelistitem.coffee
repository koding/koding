kd                    = require 'kd'
JView                 = require 'app/jview'
KDButtonViewWithMenu  = kd.ButtonViewWithMenu
ActivityItemMenuItem  = require 'activity/views/activityitemmenuitem'


module.exports = class BaseStackTemplateListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @createSettingsMenu()


  createSettingsMenu: ->

    @menu = {}

    @settings        = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'stack-settings-menu'
      itemChildClass : ActivityItemMenuItem
      delegate       : this
      iconClass      : 'arrow'
      menu           : @bound 'settingsMenu'
      style          : 'resurrection'
      callback       : (event) => @settings.contextMenu event


  addMenuItem: (title, callback) -> @menu[title] = {callback}


  settingsMenu: ->

    delegate  = @getDelegate()
    @menu     = {}

    @addMenuItem 'Show',    delegate.lazyBound 'showItemContent', this
    @addMenuItem 'Edit',    @bound 'updateStackTemplate'
    @addMenuItem 'Delete',  delegate.lazyBound 'deleteItem', this

    return @menu