kd = require 'kd'
KDDialogView = kd.DialogView
KDFormView = kd.FormView
KDInputView = kd.InputView
KDLabelView = kd.LabelView
KDView = kd.View
IDEFinderItem = require 'ide/finder/idefinderitem'


module.exports = (container, callback = kd.noop, options = {}) ->

  container.addSubView dialog = new KDDialogView
    cssClass      : kd.utils.curry "save-as-dialog", options.cssClass
    overlay       : yes
    container     : container
    height        : "auto"
    buttons       :
      Save        :
        style     : "solid green medium"
        callback  : => callback input, finderController, dialog
      Cancel      :
        style     : "solid medium nobg"
        callback  : =>
          finderController.stopAllWatchers()
          finderController.destroy()
          dialog.hide()

  dialog.on 'KDObjectWillBeDestroyed', -> container.ace?.focus()

  dialog.addSubView wrapper = new KDView
    cssClass : "kddialog-wrapper"

  wrapper.addSubView form = new KDFormView

  form.addSubView label = new KDLabelView
    title : options.inputLabelTitle or "Filename:"

  form.addSubView input = new KDInputView
    label        : label
    defaultValue : options.inputDefaultValue or ""

  form.addSubView labelFinder = new KDLabelView
    title : options.finderLabel or "Select a folder:"

  dialog.show()
  input.setFocus()

  finderController = kd.singletons['appManager'].get('Finder').create
    addAppTitle       : no
    treeItemClass     : IDEFinderItem
    nodeIdPath        : 'path'
    nodeParentIdPath  : 'parentPath'
    foldersOnly       : yes
    contextMenu       : yes
    loadFilesOnInit   : yes
    machineToMount    : options.machine

  finderController.reset()

  form.addSubView finderWrapper = new KDView cssClass : "save-as-dialog save-file-container", null
  finderWrapper.addSubView finderController.getView()
  finderWrapper.setHeight 200

  # FIXME: rootpath should be taken from options.
  # i don't want to do it for now because this file should be
  # refactored from the first line and should be moved to somewhere else.
  # for now we can live with it and assuming appManager.frontApp is IDE in
  # this case is safe because this is save/save-as modal.
  if machine = options.machine
    { rootPath } = kd.singletons.appManager.getFrontApp().workspaceData
    finderController.updateMachineRoot machine.uid, rootPath
