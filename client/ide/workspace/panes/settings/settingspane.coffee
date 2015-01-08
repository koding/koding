class IDE.SettingsPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @addSubView scrollView = new KDCustomScrollView

    @editorSettingsView   = new IDE.EditorSettingsView
    @terminalSettingsView = new IDE.TerminalSettingsView

    scrollView.wrapper.addSubView @editorSettingsView
    scrollView.wrapper.addSubView @terminalSettingsView
