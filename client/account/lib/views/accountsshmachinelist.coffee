kd                        = require 'kd'
KDListView                = kd.ListView
KDCustomHTMLView          = kd.CustomHTMLView
AccountSshMachineListItem = require './accountsshmachinelistitem'


module.exports = class AccountSshMachineList extends KDListView

  constructor: (options = {}, data) ->

    options.itemClass = AccountSshMachineListItem
    options.cssClass  = 'formline ssh-machine-list'

    super options, data


  viewAppended: ->

    header = new KDCustomHTMLView
      cssClass : 'ssh-machine-list-header'
      partial  : 'Select your VMs'

    tooltipIcon = new KDCustomHTMLView
      cssClass : 'ssh-machine-list-tooltip-icon'
    tooltipIcon.setTooltip
      title      : '''
        <div class="ssh-machine-list-tooltip">
          Please select the VM(s) where this new key should be automatically installed.<br />
          (Note: keys can only be added to an active VM)
        </div>
      '''
      placement : 'above'

    header.addSubView tooltipIcon
    @addSubView header, '', yes

    super


  getSelectedMachines: ->

    machines = item.getData() for item in @items when item.switcher.getValue()


  addFooter: ->

    @addSubView new KDCustomHTMLView
      cssClass : 'ssh-machine-list-footer'
