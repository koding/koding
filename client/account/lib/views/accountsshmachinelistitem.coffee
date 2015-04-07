kd = require 'kd'
JView = require 'app/jview'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
Machine = require 'app/providers/machine'
KDCheckBox = kd.CheckBox
KDLabelView = kd.LabelView

module.exports = class AccountSshMachineListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'ssh-machine-item'
    super options, data

    { status: { state }, label } = @data

    active = state is Machine.State.Running

    @label = new KDLabelView
      title : label
    @switcher = new KDCheckBox
      defaultValue : active
      disabled     : not active
      label        : @label


  pistachio: ->
    """
      {{> @switcher }}
      {{> @label }}
    """
