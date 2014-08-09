class FacebookTeamwork extends TeamworkWorkspace

  constructor: (options = {}, data) ->

    super options, data

    @appStorage = KD.getSingleton("appStorageController").storage "Teamwork", "1.0.1"

    @on "PanelCreated", (panel) =>
      editor = panel.getPaneByName "editor"
      editor.on "OpenedAFile", =>
        content = editor.getActivePaneContent().replace "YOUR_APP_ID", @appId
        editor.getActivePaneEditor().setValue content
        @createRunButton panel  unless @runButton

    @on "ContentImportDone", =>
      @createIndexFile()

      unless @appId and @appNamespace and @appCanvasUrl
        @showInstructions()  if @amIHost()

    @on "FacebookAppInfoTaken", (info) =>
      {@appId, @appNamespace, @appCanvasUrl} = info
      @appStorage.setValue "FacebookAppId"       , @appId
      @appStorage.setValue "FacebookAppNamespace", @appNamespace
      @appStorage.setValue "FacebookAppCanvasUrl", @appCanvasUrl
      @setAppInfoToCloud()

    @container.setClass "Facebook"
    @on "WorkspaceSyncedWithRemote", =>
      @getAppInfo()  if @amIHost()

    @getDelegate().on "TeamworkToolsModalIsReady", (modal) =>
      modal.addSubView header = new KDCustomHTMLView
        cssClass : "teamwork-modal-header"
        partial  : """
          <div class="header full-width">
            <span class="text">Facebook App Details</span>
          </div>
        """
      modal.addSubView wrapper = new KDCustomHTMLView
        cssClass : "teamwork-modal-content full-width tw-fb-revoke"
        partial  : """
          <div class="teamwork-modal-content">
            <span class="initial">Below you can find your app details.</span>
            <p>
              <span>App ID</span>         <strong>#{@appId}</strong><br />
              <span>App Namespace</span>  <strong>#{@appNamespace}</strong><br />
              <span>Canvas Url</span>     <strong>#{@appCanvasUrl}</strong><br /><br />
            </p>
          </div>
        """
      wrapper.addSubView revoke = new KDCustomHTMLView
        cssClass : "teamwork-modal-content revoke"
        partial  : """
          <p>If you want to update your Facebook App ID, App Namespace or App Canvas Url click this button to start progress.</p>
        """

      revoke.addSubView new KDButtonView
        title    : "Update"
        callback : =>
          modal.destroy()
          @showInstructions()

  showInstructions: ->
    d = @getDelegate()
    d.instructionsModal?.destroy()
    d.instructionsModal = new FacebookTeamworkInstructionsModal delegate: this

  getAppInfo: ->
    @appStorage.fetchStorage (storage) =>
      @appId        = @appStorage.getValue "FacebookAppId"
      @appNamespace = @appStorage.getValue "FacebookAppNamespace"
      @appCanvasUrl = @appStorage.getValue "FacebookAppCanvasUrl"

      unless @appId and @appNamespace and @appCanvasUrl
        @checkFiles (err, res) =>
          if res
            @showInstructions()
          else
            @startImport()
      else
        @setAppInfoToCloud()
        @checkFiles (err, res) =>
          @startImport()  unless res

  checkFiles: (callback = noop) ->
    FSHelper.exists "Web/Teamwork/Facebook", KD.getSingleton("vmController").defaultVmName, (err, res) =>
      callback err, res

  startImport: ->
    {contentDetails, playgroundManifest} = @getOptions()
    @getDelegate().showImportWarning contentDetails.url, =>
      @appStorage.setValue "FacebookAppVersion", playgroundManifest.version
      @emit "ContentImportDone"

  createRunButton: (panel) ->
    panel.header.addSubView @runButton = new KDButtonViewWithMenu
      title               : "Run"
      menu                :
        "Run on Facebook" :
          callback        : => @runOnFB()
      callback            : => @run()

  run: ->
    activePanel    = @getActivePanel()
    {paneLauncher} = activePanel
    paneLauncher.createPanes() unless paneLauncher.panesCreated
    {preview, previewPane}  = paneLauncher
    paneLauncher.handleLaunch "preview"

    editor   = activePanel.getPaneByName "editor"
    root     = "Web/Teamwork/Facebook"
    path     = FSHelper.plainPath(editor.getActivePaneFileData().path).replace root, ""
    nick     = if @amIHost() then KD.nick() else @getHost()
    target   = "https://#{nick}.kd.io/Teamwork/Facebook"
    target  += path  unless path.indexOf("localfile") > -1

    previewPane.previewer.openPath target

  runOnFB: ->
    if not @amIHost() and not @appNamespace
      return @getAppInforFromCloud => @runOnFB()

    KD.utils.createExternalLink "http://apps.facebook.com/#{@appNamespace}"

  setAppInfoToCloud: ->
    @workspaceRef.child("FacebookAppInfo").set { @appId, @appNamespace, @appCanvasUrl }

  getAppInforFromCloud: (callback = noop) ->
    @workspaceRef.once "value", (snapshot) =>
      facebookAppInfo = @reviveSnapshot(snapshot).FacebookAppInfo
      return unless facebookAppInfo

      @appId          = facebookAppInfo.appId
      @appNamespace   = facebookAppInfo.appNamespace
      @appCanvasUrl   = facebookAppInfo.appCanvasUrl

      callback()

  createIndexFile: ->
    markup = ""

    for example in @getOptions().examples
      markup += @exampleItemMarkup example.title, example.description

    markup = @examplesPageMarkup markup

    file = FSHelper.createFileInstance path: "Web/Teamwork/Facebook/index.html"
    file.save markup, (err, res) =>
      return warn err  if err

  exampleItemMarkup: (title, description) ->
    """
      <a href="https://#{KD.nick()}.kd.io/Teamwork/Facebook/#{title}/index.html">
        <div class="example">
          <h3>#{title}</h3>
          <p>#{description}</p>
        </div>
      </a>
    """

  examplesPageMarkup: (examplesMarkup) ->
    """
      <html>
        <head>
          <title>Facebook App Examples</title>
          <link rel="stylesheet" type="text/css" href="https://koding-cdn.s3.amazonaws.com/teamwork/tw-fb.css" />
        </head>
        <body>
          <div class="examples">
            #{examplesMarkup}
          </div>
        </body>
      </html>
    """

  showHintModal: ->
    editor = @getActivePanel().getPaneByName "editor"
    file   = editor.getActivePaneFileData()
    readme = FSHelper.createFileInstance path:  "#{file.parentPath}/README.md"
    readme.fetchContents (err, content) =>
      return  unless content
      @getDelegate().showMarkdownModal content
