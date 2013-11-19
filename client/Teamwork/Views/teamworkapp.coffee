class TeamworkApp extends KDObject

  filename            = if location.hostname is "localhost" then "manifest-dev" else "manifest"
  playgroundsManifest = "https://raw.github.com/koding/Teamwork/master/Playgrounds/#{filename}.json"

  constructor: (options = {}, data) ->

    super options, data

    @createTeamwork()

    if options.playground
      @doCurlRequest playgroundsManifest, (err, manifests) =>
        for manifest in manifests when manifest.name is options.playground
          url = manifest.manifestUrl
        @handlePlaygroundSelection options.playground, url
    else
      @teamwork.on "PanelCreated", =>
        @doCurlRequest playgroundsManifest, (err, manifest) =>
          @populatePlaygroundsButton manifest

  createTeamwork: ->
    options               = @getOptions()
    instanceName          = if location.hostname is "localhost" then "teamwork-local" else "kd-prod-1"
    @teamwork             = new TeamworkWorkspace
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
            title         : "Tools"
            cssClass      : "clean-gray tw-tools-button"
            callback      : => @showToolsModal @teamwork.getActivePanel(), @teamwork
          }
          title           : "Playgrounds"
          itemClass       : KDButtonViewWithMenu
          cssClass        : "clean-gray playgrounds-button"
          menu            : []
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

  populatePlaygroundsButton: (playgrounds) ->
    button   = @teamwork.getActivePanel().headerButtons.Playgrounds
    menu     = []

    playgrounds.forEach (playground) =>
      item   = {}
      {name} = playground
      item[name] = {}
      item[name].callback = =>
        @handlePlaygroundSelection name, playground.manifestUrl

      menu.push item

    button.setOption "menu", menu

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
          callback  : => @importContent url, modal, callback
        DontImport  :
          title     : "Don't import anything"
          cssClass  : "modal-cancel"
          callback  : -> modal.destroy()

  importContent: (url, modal, callback) ->
    fileName     = "file#{Date.now()}.zip"
    root         = "Web/Teamwork"
    path         = "#{root}/tmp"
    vmController = KD.getSingleton "vmController"
    vmName       = vmController.defaultVmName
    notification = new KDNotificationView
      type       : "mini"
      title      : "Fetching zip file..."
      duration   : 200000

    vmController.run "mkdir -p #{path}; cd #{path} ; wget -O #{fileName} #{url}", (err, res) =>
      return warn err if err
      notification.notificationSetTitle "Extracting zip file..."
      vmController.run "cd #{path} ; unzip #{fileName} ; rm #{fileName} ; rm -rf __MACOSX", (err, res) =>
        return warn err if err
        notification.notificationSetTitle "Checking folders..."
        FSHelper.glob "#{path}/*", vmName, (err, folders) =>
          #TODO: fatihacet - multiple folders
          folderName = FSHelper.getFileNameFromPath folders[0]
          FSHelper.exists "#{root}/#{folderName}", vmName, (err, res) =>
            if res is yes
              modal.destroy()
              modal          = new KDModalView
                title        : "Folder Exists"
                cssClass     : "modal-with-text"
                overlay      : yes
                content      : "<p>There is already a folder with the same name. Do you want to overwrite it?</p>"
                buttons      :
                  Confirm    :
                    title    : "Overwrite"
                    cssClass : "modal-clean-red"
                    callback : =>
                      @handleZipImportDone_ vmController, root, folderName, path, modal, notification, url, callback
                  Cancel     :
                    title    : "Cancel"
                    cssClass : "modal-cancel"
                    callback : =>
                      modal.destroy()
                      vmController.run "rm -rf #{path}"
                      notification.destroy()
                      @setVMRoot "#{root}/#{folderName}"
            else
              @handleZipImportDone_ vmController, root, folderName, path, modal, notification, url, callback

  showMarkdownModal: (rawContent) ->
    @teamwork.markdownContent = KD.utils.applyMarkdown rawContent  if rawContent
    modal                     = new TeamworkMarkdownModal
      content                 : @teamwork.markdownContent
      targetEl                : @teamwork.getActivePanel().headerHint

  handleZipImportDone_: (vmController, root, folderName, path, modal, notification, url, callback = noop) ->
    vmController.run "rm -rf #{root}/#{folderName} ; mv #{path}/#{folderName} #{root}", (err, res) =>
      return warn err if err
      modal.destroy()
      vmController.run "rm -rf #{path}"
      notification.destroy()
      folderPath = "#{root}/#{folderName}"
      readMeFile = "#{folderPath}/README.md"
      @setVMRoot folderPath
      callback()
      FSHelper.exists readMeFile, vmController.defaultVmName, (err, res) =>
        return unless res
        file  = FSHelper.createFileFromPath readMeFile
        file.fetchContents (err, readMeContent) => @showMarkdownModal readMeContent

  setVMRoot: (path) ->
    {finderController} = @teamwork.getActivePanel().getPaneByName "finder"
    {defaultVmName}    = KD.getSingleton "vmController"

    if finderController.getVmNode defaultVmName
      finderController.unmountVm defaultVmName

    finderController.mountVm "#{defaultVmName}:#{path}"

  showPlaygroundsModal: ->
    new TeamworkPlaygroundsModal delegate: this

  mergePlaygroundOptions: (manifest, playground) ->
    {rawOptions}                    = @teamwork
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
    @doCurlRequest manifestUrl, (err, manifest) =>
      @teamwork.startNewSession @mergePlaygroundOptions manifest, playground
      @teamwork.container.setClass playground
      @teamwork.on "WorkspaceSyncedWithRemote", =>
        {contentDetails} = @teamwork.getOptions()

        KD.mixpanel "User Changed Playground", playground

        if contentDetails.type is "zip"
          root            = "Web/Teamwork/#{playground}"
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
        else
          warn "Unhandled content type for #{name}"

  setUpImport: (url, version, playground) ->
    unless url
      return warn "Missing url parameter to import zip file for #{playground}"

    @teamwork.importInProgress = yes
    @showImportWarning url, =>
      @teamwork.emit "ContentImportDone"
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
