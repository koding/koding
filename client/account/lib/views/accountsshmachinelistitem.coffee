kd = require 'kd'
JView = require 'app/jview'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
Machine = require 'app/providers/machine'
KDCheckBox = kd.CheckBox

module.exports = class AccountSshMachineListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'ssh-machine-item'
    super options, data

    { status: { state } } = @data

    active = state is Machine.State.Running
    @switcher = new KDCheckBox
      defaultValue : active
      disabled     : not active


  pistachio: ->
    """
      {{> @switcher }}
      {{ #(label) }}
    """
