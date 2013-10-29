class TeamworkApp extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    options               = @getOptions()
    instanceName          = if location.hostname is "localhost" then "teamwork-local" else "kd-prod-1"
    additionalButton      =
      title               : "Environments"
      cssClass            : "clean-gray"
      callback            : (panel, workspace) => @showEnvironmentsModal panel, workspace

    @teamwork             = new TeamworkWorkspace
      name                : options.name                or "Teamwork"
      joinModalTitle      : options.joinModalTitle      or "Join a coding session"
      joinModalContent    : options.joinModalContent    or "<p>Paste the session key that you received and start coding together.</p>"
      shareSessionKeyInfo : options.shareSessionKeyInfo or "<p>This is your session key, you can share this key with your friends to work together.</p>"
      firebaseInstance    : options.firebaseInstance    or instanceName
      sessionKey          : options.sessionKey
      delegate            : this
      environment         : options.environment         or null
      panels              : options.panels              or [
        title             : "Teamwork"
        hint              : "<p>This is a collaborative coding environment where you can team up with others and work on the same code.</p>"
        buttons           : [
          {
            title         : "Tools"
            cssClass      : "clean-gray tw-tools-button"
            callback      : => @showToolsModal @teamwork.getActivePanel(), @teamwork
          }
          # additionalButton
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

    if options.environment
      @teamwork.on "viewAppended", (panel) =>
        @handleEnvironmentSelection options.environment

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

  showEnvironmentsModal: ->
    new TeamworkEnvironmentsModal delegate: this

  mergeEnvironmentOptions: (manifest, environment) ->
    {rawOptions}                    = @teamwork
    {name}                          = manifest
    firstPanel                      = rawOptions.panels.first
    firstPanel.title                = name
    rawOptions.environment          = environment
    rawOptions.name                 = name
    firstPanel.headerStyling        = manifest.styling
    rawOptions.examples             = manifest.examples
    rawOptions.contentDetails       = manifest.content
    rawOptions.environmentManifest  = manifest

    if manifest.importModalContent
      rawOptions.importModalContent = manifest.importModalContent

    return rawOptions

  handleEnvironmentSelection: (environment) ->
    manifestPath = "https://raw.github.com/fatihacet/TeamworkPlaygrounds/master/#{environment}.json"
    KD.utils.wait 1000, => # KNOWN ISSUE...
      KD.getSingleton("vmController").run "curl -kLs #{manifestPath}", (err, contents) =>
        try
          manifest = JSON.parse contents
        catch err
          return warn "Manifest file is broken for #{environment}"

        @teamwork.startNewSession @mergeEnvironmentOptions manifest, environment
        @teamwork.container.setClass environment
        @teamwork.on "WorkspaceSyncedWithRemote", =>
          {contentDetails} = @teamwork.getOptions()
          if contentDetails.type is "zip"
            appStorage = KD.getSingleton("appStorageController").storage "Teamwork", "1.0"
            appStorage.fetchStorage (storage) =>
              version  = appStorage.getValue "#{environment}AppVersion"
              if KD.utils.versionCompare manifest.version, "gt", version
                FSHelper.exists "Web/Teamwork/#{environment}", KD.getSingleton("vmController").defaultVmName, (err, res) =>
                  return @setVMRoot "Web/Teamwork/#{environment}"  if res
                  if contentDetails.url
                    @teamwork.importInProgress = yes
                    @showImportWarning contentDetails.url, =>
                      appStorage.setValue "#{environment}AppVersion", manifest.version
                      @teamwork.emit "ContentImportDone"
                      @teamwork.importModalContent = no
                  else
                    warn "Missing url parameter to import zip file for #{name}"
              else
                KD.singletons.vmController.fetchVMs (err, res) =>
                  @setVMRoot "Web/Teamwork/#{environment}"
          else
            warn "Unhandled content type for #{name}"
