class ApplicationTabView extends KDTabView
  constructor: (options = {}, data) ->

    options.resizeTabHandles     = yes
    options.lastTabHandleMargin  = 40
    options.sortable             = yes
    options.saveSession        or= no
    options.sessionName        or= ''
    options.sessionKey         or= 'previousSession'

    super options, data

    isSessionSupportEnabled = options.saveSession and options.sessionName
    @initSession() if isSessionSupportEnabled

    appView = @getDelegate()

    @on 'PaneRemoved', =>
      appView.emit 'AllViewsClosed' if @panes.length is 0
      @tabHandleContainer.repositionPlusHandle @handles

    @on 'PaneAdded', =>
      @tabHandleContainer.repositionPlusHandle @handles
      appView.emit 'CreateSessionData', @panes if isSessionSupportEnabled

    @on 'SaveSession', (data) =>
      @appStorage.setValue @getOptions().sessionKey, data

  initSession: ->
    options     = @getOptions()
    @appStorage = new AppStorage options.sessionName, '0.1'

    @appStorage.fetchValue options.sessionKey, (data) =>
      if data then @restoreSession data else @createNewSession()

  restoreSession: (data) ->
    return if data.length is 0
    delegator = @getDelegate()

    delegator.openFile FSHelper.createFileFromPath file for file in data

  createNewSession: ->
    @appStorage.setValue @getOptions.sessionKey, []