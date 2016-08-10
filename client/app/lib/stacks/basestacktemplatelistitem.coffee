kd                    = require 'kd'
JView                 = require 'app/jview'
KDButtonViewWithMenu  = kd.ButtonViewWithMenu
ActivityItemMenuItem  = require 'app/activity/activityitemmenuitem'


module.exports = class BaseStackTemplateListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @createSettingsMenu()


  createSettingsMenu: ->

    @menu = {}

    @settings        = new KDButtonViewWithMenu
      cssClass       : 'stack-settings-menu'
      itemChildClass : ActivityItemMenuItem
      delegate       : this
      iconClass      : 'arrow'
      menu           : @bound 'settingsMenu'
      style          : 'resurrection'
      callback       : (event) => @settings.contextMenu event


  addMenuItem: (title, callback) -> @menu[title] = { callback }


  settingsMenu: ->

    listView  = @getDelegate()
    @menu    ?= {}

    @addMenuItem 'Show', => listView.emit 'ItemAction', { action : 'ShowItem', item : this }
    @addMenuItem 'Edit', => listView.emit 'ItemAction', { action : 'EditItem', item : this }
    @addMenuItem 'Generate Stack', => listView.emit 'ItemAction', { action : 'GenerateStack', item : this }
    @addMenuItem 'Delete', => listView.emit 'ItemAction', { action : 'RemoveItem', item : this }

    return @menu
