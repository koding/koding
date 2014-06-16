class TeamworkImporter extends KDObject

  constructor: (options = {}, data) ->

    options.rootPath or= "/home/#{KD.nick()}/Web/Teamwork"

    super options, data

    @vmController  = KD.getSingleton "vmController"
    @vmName        = @vmController.defaultVmName
    {@url}         = @getOptions()

    @parseUrl()

  parseUrl: ->
    extension      = FSHelper.getFileExtension @url
    gitHubUrlRegex = /http(s)?:\/\/github.com/
    gistUrlRegex   = /http(s)?:\/\/gist.github.com/
    isGitHubUrl    = gitHubUrlRegex.test @url
    isGistUrl      = gistUrlRegex.test @url

    if isGistUrl
      gistId = @url.split("/").last
      @url   = "https://gist.github.com/#{gistId}.git"
      @cloneRepo()
    else if isGitHubUrl and extension isnt "zip"
      if extension is "git" then @cloneRepo()
      else
        @url = "#{@url}.git" # convert Github url to git url
        @cloneRepo()
    else
      switch extension
        when "zip" then @downloadZip()
        when "git" then @cloneRepo()
        else
          if @attemptedUrlResolve is yes
            return warn "Url couldn't resolved.. #{@url}"
          @resolveUrl => @parseUrl()

  downloadZip: ->
    {rootPath} = @getOptions()
    @tempPath  = "#{rootPath}/.tmp"
    fileName   = "tw-file-#{Date.now()}.zip"
    commands   = [
      "rm -rf #{@tempPath}"
      "mkdir -p #{@tempPath}"
      "cd #{@tempPath}"
      "wget -O #{fileName} #{@url}"
      "unzip #{fileName}"
      "rm #{fileName}"
      "rm -rf __MACOSX"
    ]

    @notify "Downloading zip file...", "", 25000
    commands = commands.join(" && ")
    @vmController.run commands, (err, res) =>
      return @handleError err or res.stderr  if err or res.exitStatus > 0

      FSHelper.glob "#{@tempPath}/*", @vmName, (err, folders) =>
        return @handleError err  if err
        @folderName = FSHelper.getFileNameFromPath folders.first
        folder      = FSHelper.createFileInstance path: "#{rootPath}/#{@folderName}", type: "folder"
        folder.exists (err, isExists) =>
          return @handleError err  if err
          if isExists
            @showOverwriteModal()
          else
            @importDone_()

  showOverwriteModal: (contentOptions = {}) ->
    options = @getOptions()
    options.modal?.destroy()
    @notification?.destroy()

    modal          = new KDModalView
      title        : "Folder Exists"
      cssClass     : "modal-with-text"
      overlay      : yes
      content      : contentOptions.content or "<p>There is already a folder with the same name. Do you want to overwrite it?</p>"
      buttons      :
        Confirm    :
          title    : "Overwrite"
          cssClass : "modal-clean-red"
          callback : =>
            modal.destroy()
            if   contentOptions.confirmCallback
            then contentOptions.confirmCallback modal
            else @importDone_()
        Cancel     :
          title    : "Cancel"
          cssClass : "modal-cancel"
          callback : =>
            modal.destroy()
            return  if contentOptions.cancelCallback? modal
            @vmController.run "rm -rf #{@tempPath}"
            @notification?.destroy()
            @getDelegate().setVMRoot "#{@root}/#{@folderName}"

  importDone_: ->
    options      = @getOptions()
    {rootPath}   = options
    delegate     = @getDelegate()
    command      = "rm -rf #{rootPath}/#{@folderName} ; mv #{@tempPath}/#{@folderName} #{rootPath}"

    # There wasn't an error check, added
    # but you can remove if you think its not necessary ~ GG
    @vmController.run command, (err, res) =>
      err = err or res.stderr
      return warn err  if err or res.exitStatus > 0

      options.modal?.destroy()
      @notification?.destroy()
      options.callback?()
      @vmController.run "rm -rf @{tempPath}"
      @checkContent()

  checkContent: ->
    {rootPath} = @getOptions()
    folderPath = "#{rootPath}/#{@folderName}"
    mdPath     = "#{folderPath}/README.md"
    shPath     = "#{folderPath}/install.sh"
    mdFile     = FSHelper.createFileInstance path:  mdPath
    shFile     = FSHelper.createFileInstance path:  shPath
    delegate   = @getDelegate()
    delegate.setVMRoot folderPath

    mdFile.exists (err, mdExists) =>
      if mdExists
        mdFile.fetchContents (err, mdContent) =>
          delegate = @getDelegate()
          delegate.showMarkdownModal mdContent
          delegate.mdModal.once "KDObjectWillBeDestroyed", =>
            @checkShFile shFile
      else
        @checkShFile shFile

  checkShFile: (shFile) ->
    shFile.exists (err, fileExist) =>
      return unless fileExist
      shFile.fetchContents (err, shContent) =>
        modal          = new KDModalView
          title        : "Installation Script"
          cssClass     : "modal-with-text"
          width        : 600
          overlay      : yes
          content      : """
            <p>This Playground wants to execute the following install script. Do you want to continue?</p>
            <p>
              <pre class="tw-sh-preview">#{shContent}</pre>
            </p>
          """
          buttons      :
            Install    :
              title    : "Install Script"
              cssClass : "modal-clean-green"
              callback : => @runShFile shFile, modal
            Cancel     :
              title    : "Cancel"
              cssClass : "modal-cancel"
              callback : -> modal.destroy()

  runShFile: (shFile, modal) ->
    modal.destroy()
    {paneLauncher} = @getDelegate().teamwork.getActivePanel()
    unless paneLauncher.paneVisibilityState.terminal
      paneLauncher.handleLaunch "terminal"

    @vmController.run "chmod 777 #{shFile.path}", (err, res) =>
      err = err or res.stderr
      return @handleError err  if err or res.exitStatus > 0
      paneLauncher.terminalPane.runCommand "./#{shFile.path}"

  cloneRepo: ->
    {rootPath}    = @getOptions()
    [@folderName] = FSHelper.getFileNameFromPath(@url).split ".git"
    repoFolder    = FSHelper.createFileInstance path:  "#{rootPath}/#{@folderName}", "folder"
    repoFolder.exists (err, isExists) =>
      return @handleError err  if err
      if isExists
        @showOverwriteModal
          content: "<p>Repo exists. Overwrite?</p>"
          confirmCallback: (modal) =>
            repoFolder.remove =>
              @doClone()
          cancelCallback: (modal) ->
            modal.destroy()
      else
        @doClone()

  doClone: ->
    @notify "Cloning repository...", "", 30000
    {rootPath, modal} = @getOptions()
    commands          = [
      "mkdir -p #{rootPath}"
      "cd #{rootPath}"
      "git clone #{@url}"
    ]

    modal?.destroy()
    @vmController.run commands.join(" && "), (err, res) =>
      err = err or res.stderr
      return @handleError err  if err or res.exitStatus > 0

      @getDelegate().setVMRoot "#{rootPath}/#{@folderName}"
      @notification?.destroy()
      @checkContent()

  resolveUrl: (callback = noop) ->
    @vmController.run "curl -sIL #{@url} | grep ^Location", (err, res) =>
      err = err or res.stderr
      return @handleError err  if err or res.exitStatus > 0
      longUrl = res.stdout

      message = "Url must be a GitHub repository link or a zip file."
      return @handleError { message }, message  unless longUrl

      @url = longUrl.replace("Location: ", "").replace(/\n/g, "").trim()
      @attemptedUrlResolve = yes
      callback()

  notify: (title, cssClass, duration = 4200) ->
    type = "mini"
    @notification?.destroy()
    @notification = new KDNotificationView { title, cssClass, duration, type }

  handleError: (err, message = "Something went wrong.") ->
    @notify message, "error"
    return warn err
