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
    contextMenu       : no
    loadFilesOnInit   : yes
    machineToMount    : options.machine

  finder = finderController.getView()
  finderController.reset()

  form.addSubView finderWrapper = new KDView cssClass : "save-as-dialog save-file-container", null
  finderWrapper.addSubView finder
  finderWrapper.setHeight 200
