kd = require 'kd'
IDETailerPane = require 'ide/workspace/panes/idetailerpane'
FSHelper = require 'app/util/fs/fshelper'

header = ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'

module.exports = class HomeBuildLogs extends kd.View

  constructor: (options = {}, data) ->

    { computeController } = kd.singletons

    path = kd.singletons.router.getCurrentPath()

    machineUid = path.split('/').pop()

    options.cssClass = kd.utils.curry 'Build-Logs', options.cssClass

    machine = computeController.findMachineFromMachineUId machineUid

    @machineName = machine.label

    # Path of cloud-init-output log
    path = '/var/log/cloud-init-output.log'
    @file = FSHelper.createFileInstance { path, machine }


    super options, data


  viewAppended: ->

    @addSubView @header = header()

    @header.addSubView new kd.CustomHTMLView
      tagName : 'a'
      partial : 'BACK TO VIRTUAL MACHINES'
      click : ->
        kd.singletons.router.handleRoute '/Home/Stacks/virtual-machines'

    @addSubView new kd.CustomHTMLView
      cssClass : 'pane-header'
      partial : """
        <div class='vm-name'> #{@machineName} Build Logs </div>
        <div class='title'> /var/log/cloud-init-output.log</div>
      """

    @addSubView new IDETailerPane { cssClass: 'build-logs-view', file: @file, delegate: this }
