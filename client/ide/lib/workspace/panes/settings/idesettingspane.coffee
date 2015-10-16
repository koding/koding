kd                      = require 'kd'
KDCustomScrollView      = kd.CustomScrollView
IDEEditorSettingsView   = require './ideeditorsettingsview'
IDEPane                 = require '../idepane'
IDETerminalSettingsView = require './ideterminalsettingsview'


module.exports = class IDESettingsPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'settings-pane', options.cssClass

    super options, data

    @addSubView scrollView = new KDCustomScrollView

    @editorSettingsView   = new IDEEditorSettingsView
    @terminalSettingsView = new IDETerminalSettingsView

    scrollView.wrapper.addSubView @editorSettingsView
    scrollView.wrapper.addSubView @terminalSettingsView

    @on 'EnableAutoRemovePane', => @editorSettingsView.enableAutoRemovePane.setOn()
