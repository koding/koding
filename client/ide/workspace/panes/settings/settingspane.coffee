class IDE.SettingsPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @addSubView scrollView = new KDCustomScrollView

    scrollView.wrapper.addSubView new IDE.EditorSettingsView
    scrollView.wrapper.addSubView new IDE.TerminalSettingsView
