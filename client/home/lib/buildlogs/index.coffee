kd = require 'kd'
IDETailerPane = require 'ide/workspace/panes/idetailerpane'
FSHelper = require 'app/util/fs/fshelper'
IDEHelpers = require 'ide/idehelpers'
showErrorNotification = require 'app/util/showErrorNotification'


header = ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'

module.exports = class HomeBuildLogs extends kd.View

  constructor: (options = {}, data) ->

    { computeController, router } = kd.singletons

    path = router.getCurrentPath()

    machineUid = path.split('/').pop()

    options.cssClass = kd.utils.curry 'Build-Logs', options.cssClass

    super options, data

    machine = computeController.findMachineFromMachineUId machineUid

    return router.handleNotFound path  unless machine

    @machineName = machine.label

    # Path of cloud-init-output log
    path = '/var/log/cloud-init-output.log'
    @file = FSHelper.createFileInstance { path, machine }


    @file.fetchPermissions (err, result) ->

      return showErrorNotification err  if err

      { readable, writable, exists } = result

      unless exists
        new kd.NotificationView
          title: 'Your build logs path is not exists'
          duration: 2000
        return router.handleRoute '/Home/Stacks/virtual-machines'

      unless readable
        IDEHelpers.showFileAccessDeniedError()
        return router.handleRoute '/Home/Stacks/virtual-machines'


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

    @addSubView new IDETailerPane { cssClass: 'build-logs-view', @file, delegate: this }
