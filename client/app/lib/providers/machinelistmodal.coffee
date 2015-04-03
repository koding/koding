kd = require 'kd'
KDView = kd.View
KDLabelView = kd.LabelView
KDModalView = kd.ModalView
KodingSwitch = require 'app/commonviews/kodingswitch'
showError = require 'app/util/showError'
machineList = require './machinelist'
_ = require 'lodash'

module.exports = class MachineListModal extends KDModalView

  constructor: (options = {}, data)->

    options = _.extend
      title        : "Machine List"
      subtitle     : "Select a running machine below to perform this action."
      cssClass     : "machines-modal"
      width        : 540
      overlay      : yes
      buttons      :
        "Continue" :
          disabled : yes
          callback : => @continueAction()
    , options

    super options, data

  viewAppended:->

    machineList = new MachineList @getOption 'listOptions'

    rememberMachineView = new KDView
      cssClass     : "remember-machine"
    rememberMachineView.addSubView new KDLabelView
      title        : "Use selected machine for the same action next time"
    rememberMachineView.addSubView @checkBox = new KodingSwitch
      defaultValue : off
      size         : "tiny"

    @addSubView machineList
    @addSubView rememberMachineView

    machineList.on "ItemSelectionPerformed", (list, {items})=>

      @machine = items.first.getData()
      @buttons["Continue"][ \
        if @checkMachineState() then 'enable' else 'disable'
      ]()


  checkMachineState: ->

    # FIXME Make this check extendable
    @machine?.status.state is Machine.State.Running


  continueAction:->

    if @checkMachineState()
      @emit "MachineSelected", @machine, @checkBox.getValue()
      @destroy()
