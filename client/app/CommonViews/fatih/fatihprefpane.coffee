class FatihPrefPane extends JView

  constructor: (options = {}, data) ->

    super options, data

    @tabView            = new KDTabView

    @defaultPluginsPane = new KDTabPaneView
      title             : "Default Search"
      closable          : no

    @aliasesPane        = new KDTabPaneView
      title             : "Aliases"
      closable          : no

    @customPluginsPane  = new KDTabPaneView
      cssClass          : "coming-soon"
      title             : "Custom Plugins"
      closable          : no
      partial           : "Coming soon..."

    panes               = [@defaultPluginsPane, @aliasesPane, @customPluginsPane]

    @tabView.addPane pane for pane in panes
    @tabView.showPaneByIndex 0

    @tabView.addSubView new KDCustomHTMLView
      cssClass : "fatih-pref-pane-close"
      click    : =>
        @getDelegate().showStaticViews()
        @destroy()

    @fetchUserPreferences (prefs = {}) =>
      @createSearchTargetsPane prefs.search
      @createAliasesPane       prefs.aliases

  fetchUserPreferences: (callback) ->
    fatih    = @getDelegate()
    # TODO: Defaults object should create itself
    defaults =
      search     :
        find     : yes
        search   : no
        user     : no
        open     : no
      aliases    :
        find     : "find"
        search   : "search"
        user     : "user"
        open     : "open"

    fatih.getFromStorage "preferences", (prefs) =>
      fatih.setToStorage "preferences", defaults unless prefs
      callback? prefs or defaults

  createSearchTargetsPane: (prefs) ->
    fatih         = @getDelegate()
    fatihPlugins  = fatih.plugins
    container     = @defaultPluginsPane
    @switches    = []

    for own plugin of fatihPlugins
      onOffSwitch = new KDOnOffSwitch
        keyword      : plugin
        defaultValue : prefs[plugin]
        callback     : => @savePrefs()

      @switches.push onOffSwitch

      container.addSubView new FatihPrefItem
        label        : fatihPlugins[plugin].getOption "name"
        childView    : onOffSwitch

  createAliasesPane: (prefs) ->
    fatih         = @getDelegate()
    fatihPlugins  = fatih.plugins
    container     = @aliasesPane
    @inputs       = []

    for own plugin of fatihPlugins
      input = new KDInputView
        keyword      : plugin
        defaultValue : prefs[plugin]
        change       : => @savePrefs()

      @inputs.push input

      container.addSubView new FatihPrefItem
        label        : fatihPlugins[plugin].getOption "name"
        childView    : input

  getPrefs: ->
    prefs =
      search : {}
      aliases: {}

    for switchy in @switches
      prefs.search[switchy.getOption "keyword"] = switchy.getValue()

    for input in @inputs
      prefs.aliases[input.getOption "keyword"]  = input.getValue()

    return prefs

  savePrefs: ->
    fatih    = @getDelegate()
    newPrefs = @getPrefs()
    fatih.setToStorage "preferences", newPrefs
    fatih.emit "ShouldUpdatePluginPreferences", newPrefs

  pistachio: ->
    """
      {{> @tabView}}
    """


class FatihPrefItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "fatih-pref-item"

    super options, data

    @label = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "fatih-pref-label"
      partial  : @getOption "label"

    @child = @getOptions().childView or new KDView

  pistachio: ->
    """
      {{> @label}}
      {{> @child}}
    """