class IDE.SettingsPane extends IDE.Pane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'settings-pane', options.cssClass

    super options, data

    @addSubView new IDE.EditorSettingsView
    @addSubView new IDE.TerminalSettingsView

    # TODO: reimplement these settings
    # <p class='hidden'>Highlight selected word {{> @highlightWord}}</p>
    # <p class='hidden'>             {{> @shortcuts}}</p>
    # <p class="with-select">Syntax  {{> @syntax}}</p>
    # <p>Open Recent Files           {{> @openRecentFiles}}</p>
