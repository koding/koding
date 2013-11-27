class TeamworkApp extends KDObject

  filename            = if location.hostname is "localhost" then "manifest-dev" else "manifest"
  playgroundsManifest = "https://raw.github.com/koding/Teamwork/master/Playgrounds/#{filename}.json"

  constructor: (options = {}, data) ->

    super options, data

    @appView   = @getDelegate()
    @dashboard = new TeamworkDashboard
      delegate : this

    @doCurlRequest playgroundsManifest, (err, manifest) =>
      @playgroundsManifest = manifest
      @dashboard.emit "PlaygroundsFetched", @playgroundsManifest

    @appView.addSubView @dashboard

    @on "NewSessionRequested", (callback = noop) =>
      @dashboard.hide()
      @teamwork?.destroy()
      @createTeamwork()
      @appView.addSubView @teamwork
      callback()

    @on "JoinSessionRequested", (sessionKey) =>
      @setOption "sessionKey", sessionKey
      @emit "NewSessionRequested"

    @on "ImportRequested", (importUrl) =>
      @emit "NewSessionRequested"
      @teamwork.on "WorkspaceSyncedWithRemote", =>
        @showImportWarning importUrl

    @on "TeamUpRequested", =>
      @teamwork.once "WorkspaceSyncedWithRemote", ->
        log "TEAM UP PANPAAAAA!"

  createTeamwork: (options) ->
    @teamwork = new TeamworkWorkspace options or @getTeamworkOptions()

  getTeamworkOptions: ->
    options               = @getOptions()
    instanceName          = if location.hostname is "localhost" then "teamwork-local" else "kd-prod-1"
    return {
      name                : options.name                or "Teamwork"
      joinModalTitle      : options.joinModalTitle      or "Join a coding session"
      joinModalContent    : options.joinModalContent    or "<p>Paste the session key that you received and start coding together.</p>"
      shareSessionKeyInfo : options.shareSessionKeyInfo or "<p>This is your session key, you can share this key with your friends to work together.</p>"
      firebaseInstance    : options.firebaseInstance    or instanceName
      sessionKey          : options.sessionKey
      delegate            : this
      playground          : options.playground          or null
      panels              : options.panels              or [
        title             : "Teamwork"
        hint              : "<p>This is a collaborative coding environment where you can team up with others and work on the same code.</p>"
        buttons           : [
          {
            title         : "Share"
            cssClass      : "clean-gray"
            callback      : => log "hello"
          }
        ]
        floatingPanes     : [ "chat" , "terminal", "preview" ]
        layout            :
          direction       : "vertical"
          sizes           : [ "250px", null ]
          splitName       : "BaseSplit"
          views           : [
            {
              type        : "finder"
              name        : "finder"
            }
            {
              type        : "tabbedEditor"
              name        : "editor"
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

    modal.addSubView new TeamworkTools { modal, panel, workspace, twApp: this }
    @emit "TeamworkToolsModalIsReady", modal

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
    {finderController} = @teamwork.getActivePanel().getPaneByName "finder"
    {defaultVmName}    = KD.getSingleton "vmController"

    if finderController.getVmNode defaultVmName
      finderController.unmountVm defaultVmName

    finderController.mountVm "#{defaultVmName}:#{path}"

  showPlaygroundsModal: ->
    new TeamworkPlaygroundsModal
      delegate    : this
      playgrounds : @playgroundsManifest

  mergePlaygroundOptions: (manifest, playground) ->
    rawOptions                      = @getTeamworkOptions()
    {name}                          = manifest
    firstPanel                      = rawOptions.panels.first
    firstPanel.title                = name
    rawOptions.playground           = playground
    rawOptions.name                 = name
    firstPanel.headerStyling        = manifest.styling
    rawOptions.examples             = manifest.examples
    rawOptions.contentDetails       = manifest.content
    rawOptions.playgroundManifest   = manifest

    if manifest.importModalContent
      rawOptions.importModalContent = manifest.importModalContent

    return rawOptions

  handlePlaygroundSelection: (playground, manifestUrl) ->
    unless manifestUrl
      for manifest in @playgroundsManifest when playground is manifest.name
        {manifestUrl} = manifest

    @doCurlRequest manifestUrl, (err, manifest) =>
      @teamwork?.destroy()
      @createTeamwork @mergePlaygroundOptions manifest, playground
      @appView.addSubView @teamwork
      @teamwork.container.setClass playground
      @teamwork.on "WorkspaceSyncedWithRemote", =>
        {contentDetails} = @teamwork.getOptions()

        KD.mixpanel "User Changed Playground", playground

        if contentDetails.type is "zip"
          root            = "/home/#{@teamwork.getHost()}/Web/Teamwork/#{playground}"
          folder          = FSHelper.createFileFromPath root, "folder"
          contentUrl      = contentDetails.url
          manifestVersion = manifest.version

          folder.exists (err, exists) =>
            return @setUpImport contentUrl, manifestVersion, playground  unless exists

            appStorage  = KD.getSingleton("appStorageController").storage "Teamwork", "1.0"
            appStorage.fetchStorage (storage) =>
              currentVersion  = appStorage.getValue "#{playground}PlaygroundVersion"
              hasNewVersion   = KD.utils.versionCompare manifestVersion, "gt", currentVersion
              if hasNewVersion
                @setUpImport contentUrl, manifestVersion, playground
              else
                @setVMRoot root
                @teamwork.emit "ContentIsReady"
        else
          warn "Unhandled content type for #{name}"

  setUpImport: (url, version, playground) ->
    unless url
      return warn "Missing url parameter to import zip file for #{playground}"

    @teamwork.importInProgress = yes
    @showImportWarning url, =>
      @teamwork.emit "ContentIsReady"
      @teamwork.importModalContent = no
      appStorage = KD.getSingleton("appStorageController").storage "Teamwork", "1.0"
      appStorage.setValue "#{playground}PlaygroundVersion", version

  doCurlRequest: (path, callback = noop) ->
    KD.getSingleton("vmController").run "curl -kLs #{path}", (err, contents) =>
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
