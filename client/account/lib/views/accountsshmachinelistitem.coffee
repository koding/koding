kd = require 'kd'
JView = require 'app/jview'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
Machine = require 'app/providers/machine'
KodingSwitch = require 'app/commonviews/kodingswitch'

module.exports = class AccountSshMachineListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { status: { state } } = @data

    active = state is Machine.State.Running
    @switcher = new KodingSwitch
      defaultValue : active
      disabled     : not active


  pistachio: ->
    """
      <div class="ssh-machine-item">
        {{ #(label) }}
        {{> @switcher }}
      </div>
    """
