class TeamworkApp extends KDObject

  instanceName = if KD.config.environment is "vagrant" then "koding-tw-local" else "koding-teamwork"

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
          @createTeamwork options, =>
            @teamwork.once "WorkspaceSyncedWithRemote", =>
              @setVMRoot "/home/#{@teamwork.getHost()}/Web/Teamwork/#{val.playground}"
        else
          @createTeamwork()

      KD.mixpanel "Teamwork join session, click"

    @on "ImportRequested", (importUrl) =>
      @emit "NewSessionRequested"
      @teamwork.on "WorkspaceSyncedWithRemote", =>
        @showImportWarning importUrl

  createTeamwork: (options, callback) ->
    playgroundClass = TeamworkWorkspace
    if options?.playground
      playgroundClass = if options.playground is "Facebook" then FacebookTeamwork else PlaygroundTeamwork

    @teamwork?.destroy()
    @teamwork = new playgroundClass options or @getTeamworkOptions()
    @appView.addSubView @teamwork
    callback?()

    @setOption "sessionKey", @teamwork.sessionKey
    KD.getSingleton("router").handleRoute "/Teamwork?sessionKey=#{@teamwork.sessionKey}",
      replaceState      : yes
      suppressListeners : yes

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
              treeItemClass: TeamworkFinderItem
              treeControllerClass: TeamworkFinderTreeController
            }
            {
              type        : "custom"
              paneClass   : TeamworkTabView
              name        : "tabView"
            }
          ]
      ]
    }

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
            KD.mixpanel "Teamwork import confirm, click"
        DontImport  :
          title     : "Don't import anything"
          cssClass  : "modal-cancel"
          callback  : ->
            modal.destroy()
            KD.mixpanel "Teamwork import confirm, fail"

  showMarkdownModal: (rawContent) ->
    t = @teamwork
    t.markdownContent = KD.utils.applyMarkdown rawContent  if rawContent
    modal = @mdModal  = new TeamworkMarkdownModal
      content         : t.markdownContent
      targetEl        : t.getActivePanel().headerHint

  setVMRoot: (path) ->
    panel = @teamwork.getActivePanel()
    return  unless panel
    {finderController} = @teamwork.getActivePanel().getPaneByName "finder"

    cb = (vmName) ->
      finderController.updateVMRoot vmName, path

    vmController = KD.getSingleton "vmController"
    {defaultVmName} = vmController
    if defaultVmName
    then cb defaultVmName
    else vmController.fetchDefaultVmName cb

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
      return KD.showError err  if err
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
        options = @mergePlaygroundOptions manifest, playground
        delete options.sessionKey
        @createTeamwork options
        @teamwork.container.setClass playground
        @teamwork.once "WorkspaceSyncedWithRemote", =>
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
    , (err, res) ->
      return warn err  if err
      return warn res.stderr if res.exitStatus > 0

      contents  = res.stdout
      extension = FSHelper.getFileExtension path
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
      url           : "https://resources.kd.io/Teamwork/Playgrounds/#{path}"
      type          : "GET"
      success       : (response) ->
        return callback yes, null  unless response
        callback null, response
      error         : ->
        return callback yes, null
