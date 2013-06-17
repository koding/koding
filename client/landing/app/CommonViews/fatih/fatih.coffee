class Fatih extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass       = "fatih"
    options.width          = 500
    options.position       =
      top : "10%"

    super options, data

    @plugins               = {}
    @activePlugin          = null
    @lastPressedKey        = null
    @defaultPluginsRunning = no

    @addSubView @input = new KDHitEnterInputView
      type            : "text"
      cssClass        : "fatih-search-input"
      keyup           :
        "esc"         : => @destroy()
      callback        : (keyword) =>
        log "fatih triggered"
        return if keyword.length is 0
        @loader.show()
        @input.focus()
        @defaultPluginsRunning = no
        @destroyPluginSubViews()
        @activePlugin          = null
        keyword                = @splitKeyword keyword
        plugin                 = @detectPlugin keyword[0]

        return plugin.emit "FatihQueryPerformed", keyword[1] if plugin

        log "cannot detect any plugin"

        @runDefaultPlugins keyword[1]

    @addSubView @loader = new KDLoaderView
      size      :
        width   : 36

    @addSubView @prefIcon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "fatih-pref-icon"
      click     : =>
        @hideStaticViews()
        @destroyPluginSubViews yes
        @addSubView new FatihPrefPane
          delegate: @

    @loader.hide()
    @setMagicKeyCombo()

    @hide()

    @on "PluginViewReadyToShow", (view) ->
      log "plugin view ready to show", view
      @destroyPluginSubViews()
      @showPluginView view
      @loader.hide()

    @on "PluginFoundNothing", ->
      return if @defaultPluginsRunning
      @loader.hide()
      @destroyPluginSubViews()
      @addSubView new KDView
        partial  : @activePlugin.getOption "notFoundText"
        cssClass : "not-found"

    @on "ShouldUpdatePluginPreferences", (newPrefs) =>
      @updatePluginsKeyword newPrefs
      @fetchStorage()

    KD.getSingleton("mainController").on "AppIsReady", =>
      @appStorage = new AppStorage "Fatih", "1.0"
      @fetchStorage =>
        @getFromStorage "preferences", (prefs) =>
          @updatePluginsKeyword prefs

      @addDefaultPlugins()

      @plugins[plugin].registerIndex() for plugin of @plugins when @isUserLoggedIn()

    # @on "ReceivedClickElsewhere", => @destroy()

  setMagicKeyCombo: ->
    KD.getSingleton('windowController').on "keydown", (e) =>
      isCtrlAndSpacePressed  = e.which is 32 and e.ctrlKey
      isOptionPressed        = e.which is 18
      isLastPressedKeyOption = @lastPressedKey is 18

      @utils.wait 300, => @lastPressedKey = null if isOptionPressed

      if ((isOptionPressed and isLastPressedKeyOption) or isCtrlAndSpacePressed) and @isUserLoggedIn()
        @show()
        @showStaticViews()
        @input.setFocus()
        KD.getSingleton("windowController").addLayer @

      @lastPressedKey = e.which

  splitKeyword: (keyword) ->
    [pluginKeyword, searchKeyword] = keyword.split " "
    unless searchKeyword
      searchKeyword = pluginKeyword
      pluginKeyword = ""

    return [pluginKeyword, searchKeyword]

  detectPlugin: (pluginKeyword) ->
    plugin = null
    for currentPlugin of @plugins
      if @plugins[currentPlugin].getOption("keyword") is pluginKeyword
        plugin = @plugins[currentPlugin]

    if plugin
      @activePlugin = plugin
      log "plugin is:", plugin
      return plugin

  updatePluginsKeyword: (prefs) ->
    return unless prefs
    for plugin of @plugins
      keyword = prefs.aliases?[plugin]
      @plugins[plugin].setOption "keyword", keyword if keyword
      # log "#{plugin}'s keyword set to #{prefs.aliases[plugin]}"

  runDefaultPlugins: (keyword) ->
    @defaultPluginsRunning = yes
    @getFromStorage "preferences", (prefs) =>
      searchablePlugins = prefs.search
      hasFoundAnyPlugin = no

      for plugin of searchablePlugins when searchablePlugins[plugin] is yes
        plugin = @plugins[plugin]
        @activePlugin = plugin
        plugin.emit "FatihQueryPerformed", keyword
        log "emitted query performed with", plugin
        hasFoundAnyPlugin = yes

      @loader.hide() unless hasFoundAnyPlugin

  addDefaultPlugins: ->
    @addPlugin @createPluginInstance FatihFileFinderPlugin
    @addPlugin @createPluginInstance FatihContentSearchPlugin
    @addPlugin @createPluginInstance FatihOpenAppPlugin
    @addPlugin @createPluginInstance FatihUserSearchPlugin

  addPlugin: (pluginInstance) ->
    @plugins[pluginInstance.getOption "keyword"] = pluginInstance

  addThirdPartyPlugin: (options) ->
    return unless options or options.keyword
    options.thirdParty = yes
    plugin = new FatihPluginAbstract options
    plugin.fatihView = @
    @addPlugin plugin

  createPluginInstance: (ClassName, options = {}, data = {}) ->
    return unless ClassName
    options.delegate = @
    new ClassName options, data

  showPluginView: (view) ->
    {showResultIn}   = @activePlugin.getOptions()

    switch showResultIn
      when "fatih"    then @addSubView view
      when "newtab"   then log "should show in new tab"
      when "preview"  then log "should open in preview"

  registerIndex: (pluginKeyword, indexData = {}) ->
    return unless pluginKeyword
    @indexes[pluginKeyword] = indexData

  fetchStorage: (callback = noop) ->
    @appStorage.fetchStorage callback

  getFromStorage: (key, callback) ->
    data = @appStorage.getValue key
    callback? data

  setToStorage: (key, value) ->
    @appStorage.setValue key, value

  getStaticViews: ->
    return [@input, @loader, @prefIcon]

  hideStaticViews: ->
    view.hide() for view in @getStaticViews()
    @isStaticViewsHidden = yes

  showStaticViews: ->
    return unless @isStaticViewsHidden
    view.show() for view in @getStaticViews() when view isnt @loader

  destroyPluginSubViews: (isTheForceStrongWithThisOne) ->
    return if @defaultPluginsRunning and not isTheForceStrongWithThisOne
    subViews    = @getSubViews()
    len         = subViews.length
    statics     = @getStaticViews()
    staticsLen  = statics.length

    return if len is staticsLen
    for i in [len - 1..staticsLen]
      subViews[i].destroy()

  isUserLoggedIn: ->
    return KD.whoami() instanceof KD.remote?.api?.JAccount

  destroy: ->
    @hide()
    @loader.hide()
    @defaultPluginsRunning = no
    @destroyPluginSubViews()
    @input.setValue ""
