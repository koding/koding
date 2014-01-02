class TeamworkApp extends KDObject

  instanceName = if location.hostname.indexOf("local") > -1 then "tw-local" else "kd-prod-1"

  constructor: (options = {}, data) ->
    options.query or= {}
    super options, data

    @appView = @getDelegate()

    @on "NewSessionRequested", (options, callback) =>
      @unsetOption "sessionKey"
      @createTeamwork options, callback

    @on "JoinSessionRequested", (sessionKey) =>
      @setOption "sessionKey", sessionKey
      firebase = new Firebase "https://#{instanceName}.firebaseio.com/"
      firebase.child(sessionKey).once "value", (snapshot) =>
        val = snapshot.val()
        if val?.playground
          @setOption "playgroundManifest", val.playgroundManifest
          @setOption "playground", val.playground
          options = @mergePlaygroundOptions val.playgroundManifest, val.playground
          @createTeamwork options
        else
          @createTeamwork()

    @on "ImportRequested", (importUrl) =>
      @emit "NewSessionRequested"
      @teamwork.on "WorkspaceSyncedWithRemote", =>
        @showImportWarning importUrl

    @on "ExportRequested", (callback = noop) =>
      @showExportModal()
      @tools.once "Exported", callback # TODO: what a great event name

    @on "TeamUpRequested", =>
      @teamwork.once "WorkspaceSyncedWithRemote", =>
        @showTeamUpModal()

    {sessionKey, importUrl} = options.query
    if sessionKey     then @emit "JoinSessionRequested", sessionKey
    else if importUrl then @emit "ImportRequested"     , importUrl
    else @emit "NewSessionRequested"

  createTeamwork: (options, callback) ->
    playgroundClass = TeamworkWorkspace
    if options?.playground
      playgroundClass = if options.playground is "Facebook" then FacebookTeamwork else PlaygroundTeamwork

    @teamwork?.destroy()
    @teamwork = new playgroundClass options or @getTeamworkOptions()
    @appView.addSubView @teamwork
    callback?()

  showTeamUpModal: ->
    @showToolsModal @teamwork.getActivePanel(), @teamwork
    @tools.teamUpHeader.emit "click"
    @tools.setClass "team-up-mode"

  showExportModal: ->
    @showToolsModal @teamwork.getActivePanel(), @teamwork
    @tools.shareHeader.emit "click"
    @tools.setClass "share-mode"

  getTeamworkOptions: ->
    options               = @getOptions()
    return {
      name                : options.name                or "Teamwork"
      joinModalTitle      : options.joinModalTitle      or "Join a coding session"
      joinModalContent    : options.joinModalContent    or "<p>Paste the session key that you received and start coding together.</p>"
      shareSessionKeyInfo : options.shareSessionKeyInfo or "<p>This is your session key, you can share this key with your friends to work together.</p>"
      firebaseInstance    : options.firebaseInstance    or instanceName
      sessionKey          : options.sessionKey
      activityId          : options.query.activityId
      delegate            : this
      enableChat          : yes
      chatPaneClass       : TeamworkChatPane
      playground          : options.playground          or null
      panels              : options.panels              or [
        hint              : "<p>This is a collaborative coding environment where you can team up with others and work on the same code.</p>"
        buttons           : []
        layout            :
          direction       : "vertical"
          sizes           : [ "265px", null ]
          splitName       : "BaseSplit"
          views           : [
            {
              title       : "<div class='header-title'><span class='icon'></span>Teamwork</div>"
              type        : "finder"
              name        : "finder"
              editor      : "tabView"
            }
            {
              type        : "custom"
              paneClass   : TeamworkTabView
              name        : "tabView"
            }
          ]
      ]
    }

  showToolsModal: (panel, workspace) ->
    modal       = new KDModalView
      cssClass  : "teamwork-tools-modal"
      title     : "Teamwork Tools"
      overlay   : yes
      width     : 600

    modal.addSubView @tools = new TeamworkTools { modal, panel, workspace, twApp: this }
    @emit "TeamworkToolsModalIsReady", modal
    @forwardEvent @tools, "Exported"

  showImportWarning: (url, callback = noop) ->
    @importModal?.destroy()
    modal           = @importModal = new KDModalView
      title         : "Import File"
      cssClass      : "modal-with-text"
      overlay       : yes
      content       : @teamwork.getOptions().importModalContent or """
        <p>This Teamwork URL wants to download a file to your VM from <strong>#{url}</strong></p>
        <p>Would you like to import and start working with these files?</p>
      """
      buttons       :
        Import      :
          title     : "Import"
          cssClass  : "modal-clean-green"
          loader    :
            color   : "#FFFFFF"
            diameter: 14
          callback  : =>
            new TeamworkImporter { url, modal, callback, delegate: this }
        DontImport  :
          title     : "Don't import anything"
          cssClass  : "modal-cancel"
          callback  : -> modal.destroy()

  showMarkdownModal: (rawContent) ->
    t = @teamwork
    t.markdownContent = KD.utils.applyMarkdown rawContent  if rawContent
    modal = @mdModal  = new TeamworkMarkdownModal
      content         : t.markdownContent
      targetEl        : t.getActivePanel().headerHint

  setVMRoot: (path) ->
    @teamwork.once "WorkspaceSyncedWithRemote", =>
      {finderController} = @teamwork.getActivePanel().getPaneByName "finder"
      {defaultVmName}    = KD.getSingleton "vmController"

      if finderController.getVmNode defaultVmName
        finderController.unmountVm defaultVmName

      finderController.mountVm "#{defaultVmName}:#{path}"

  mergePlaygroundOptions: (manifest, playground) ->
    rawOptions                      = @getTeamworkOptions()
    {name}                          = manifest
    rawOptions.headerStyling        = manifest.styling
    rawOptions.playground           = playground
    rawOptions.name                 = name
    rawOptions.examples             = manifest.examples
    rawOptions.contentDetails       = manifest.content
    rawOptions.playgroundManifest   = manifest

    if manifest.importModalContent
      rawOptions.importModalContent = manifest.importModalContent

    return rawOptions

  getPlaygroundClass: (playground) ->
    return if playground is "Facebook" then FacebookTeamwork else PlaygroundTeamwork

  handlePlaygroundSelection: (playground, manifestUrl) ->
    {teamwork} = this

    teamwork.getActivePanel().setClass "hidden"
    teamwork.chatView.setClass "hidden"
    teamwork.createLoader()
    teamwork.loader.addSubView loadingText = new KDCustomHTMLView
      partial  : "Loading your #{playground} playground. Please wait..."
      cssClass : "tw-loader-text"

    unless manifestUrl
      for manifest in @playgroundsManifest when playground is manifest.name
        {manifestUrl} = manifest

    @doCurlRequest manifestUrl, (err, manifest) =>
      root            = "/home/#{@teamwork.getHost()}/Web/Teamwork/#{playground}"
      folder          = FSHelper.createFileFromPath root, "folder"
      contentUrl      = manifest.content.url
      manifestVersion = manifest.version

      folder.exists (err, exists) =>
        return @setUpImport manifest, playground  unless exists

        appStorage  = KD.getSingleton("appStorageController").storage "Teamwork", "1.0.1"
        appStorage.fetchStorage (storage) =>
          currentVersion  = appStorage.getValue "#{playground}PlaygroundVersion"
          hasNewVersion   = KD.utils.versionCompare manifestVersion, "gt", currentVersion
          if hasNewVersion
            @setUpImport manifest, playground
          else
            @emit "PlaygroundContentIsReady"

      @once "PlaygroundContentIsReady", =>
        @teamwork.destroy()
        @createTeamwork @mergePlaygroundOptions manifest, playground
        @appView.addSubView @teamwork
        @teamwork.container.setClass playground
        @setVMRoot root

  setUpImport: (manifest, playground) ->
    {version} = manifest
    {url}     = manifest.content

    unless url
      return warn "Missing url parameter to import zip file for #{playground}"

    @teamwork.importInProgress = yes
    modal    = null
    callback = =>
      @emit "PlaygroundContentIsReady"
      @teamwork.importModalContent = no
      appStorage = KD.getSingleton("appStorageController").storage "Teamwork", "1.0.1"
      appStorage.setValue "#{playground}PlaygroundVersion", version

    new TeamworkImporter { url, modal, callback, delegate: this }

  doCurlRequest: (path, callback = noop) ->
    vmController = KD.getSingleton "vmController"
    vmController.run
      withArgs: "curl -kLs #{path}"
      vmName  : vmController.defaultVmName
    , (err, contents) =>
      extension = FSItem.getFileExtension path
      error     = null

      switch extension
        when "json"
          try
            manifest = JSON.parse contents
          catch err
            error    = "Manifest file is broken for #{path}"

          callback error, manifest
        when "md"
          callback errorMessage, KD.utils.applyMarkdown error, contents

  fetchManifestFile: (path, callback = noop) ->
    $.ajax
      url           : "http://resources.gokmen.kd.io/Teamwork/Playgrounds/#{path}"
      type          : "GET"
      success       : (response) ->
        return callback yes, null  unless response
        callback null, response
      error         : ->
        return callback yes, null
