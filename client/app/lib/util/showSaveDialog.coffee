kd              = require 'kd'
KDView          = kd.View
KDFormView      = kd.FormView
KDInputView     = kd.InputView
KDLabelView     = kd.LabelView
KDDialogView    = kd.DialogView
IDEFinderItem   = require 'ide/finder/idefinderitem'


module.exports = showSaveDialog = (container, callback = kd.noop, options = {}) ->

  container.addSubView dialog = new KDDialogView
    cssClass      : kd.utils.curry 'save-as-dialog', options.cssClass
    overlay       : yes
    container     : container
    height        : 'auto'
    buttons       :
      save        :
        title     : 'SAVE'
        style     : 'GenericButton primary'
        callback  : -> callback input, finderController, dialog
      cancel      :
        title     : 'CANCEL'
        style     : 'GenericButton cancel'
        callback  : ->
          finderController.stopAllWatchers()
          finderController.destroy()
          dialog.hide()

  dialog.addSubView wrapper = new KDView
    cssClass : 'kddialog-wrapper'

  wrapper.addSubView form = new KDFormView

  form.addSubView label = new KDLabelView
    title : options.inputLabelTitle or 'Filename:'

  form.addSubView input = new KDInputView
    label        : label
    defaultValue : options.inputDefaultValue or ''
    keydown      : (event) ->
      dialog.buttons.save.click()  if event.which is 13

  dialog.on 'KDObjectWillBeDestroyed', ->
    container.ace?.focus()
    input.blur()
    input.off 'keydown'

  form.addSubView new KDLabelView
    title : options.finderLabel or 'Select a folder:'

  dialog.show()
  input.setFocus()

  finderController = kd.singletons.appManager.get('Finder').create
    addAppTitle       : no
    treeItemClass     : IDEFinderItem
    nodeIdPath        : 'path'
    nodeParentIdPath  : 'parentPath'
    foldersOnly       : yes
    contextMenu       : yes
    loadFilesOnInit   : yes
    machineToMount    : options.machine
    saveChanges       : no

  finderController.reset()

  form.addSubView finderWrapper = new KDView { cssClass : 'save-as-dialog save-file-container' }, null
  finderWrapper.addSubView finderController.getView()
  finderWrapper.setHeight 200
