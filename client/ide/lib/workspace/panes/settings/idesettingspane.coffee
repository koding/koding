EditorSettingsView   = require './editorsettingsview'
TerminalSettingsView = require './terminalsettingsview'
Pane                 = require '../pane'


class SettingsPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @addSubView scrollView = new KDCustomScrollView

    @editorSettingsView   = new EditorSettingsView
    @terminalSettingsView = new TerminalSettingsView

    scrollView.wrapper.addSubView @editorSettingsView
    scrollView.wrapper.addSubView @terminalSettingsView


module.exports = SettingsPane
