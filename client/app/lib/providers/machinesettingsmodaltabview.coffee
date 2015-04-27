kd        = require 'kd'
KDTabView = kd.TabView


module.exports = class MachineSettingsModalTabView extends KDTabView

  showPane: (pane) ->

    if pane.getOptions().disabled
      return no

    super
