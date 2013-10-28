class FacebookTeamwork extends TeamworkWorkspace

  constructor: (options = {}, data) ->

    super options, data

    @appStorage = KD.getSingleton("appStorageController").storage "Teamwork"

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

    @container.setClass "Facebook"
    @on "WorkspaceSyncedWithRemote", =>
      @getAppInfo()  if @amIHost()

  showInstructions: ->
    @instructionsModal = new FacebookTeamworkInstructionsModal delegate: this

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
        @checkFiles (err, res) =>
          @startImport()  unless res

  checkFiles: (callback = noop) ->
    FSHelper.exists "Web/Teamwork/Facebook", KD.getSingleton("vmController").defaultVmName, (err, res) =>
      callback err, res

  startImport: ->
    {contentDetails, environmentManifest} = @getOptions()
    @getDelegate().showImportWarning contentDetails.url, =>
      @appStorage.setValue "FacebookAppVersion", environmentManifest.version
      @emit "ContentImportDone"

  createRunButton: (panel) ->
    # panel.headerButtons.Environments.hide()
    panel.header.addSubView @runButton = new KDButtonViewWithMenu
      title               : "Run"
      menu                :
        "Run"             :
          callback        : => @run()
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
    nick     = if @amIHost() then KD.nick() else @getSessionOwner()
    target   = "https://#{nick}.kd.io/Teamwork/Facebook"
    target  += path  unless path.indexOf("localfile") > -1

    previewPane.previewer.openPath target

  runOnFB: ->
    KD.utils.createExternalLink "http://apps.facebook.com/#{@appNamespace}"

  createIndexFile: ->
    markup = ""

    for example in @getOptions().examples
      markup += @exampleItemMarkup example.title, example.description

    markup = @examplesPageMarkup markup

    file = FSHelper.createFileFromPath "Web/Teamwork/Facebook/index.html"
    file.save markup, (err, res) =>
      return warn err  if err

  exampleItemMarkup: (title, description) ->
    """
      <div class="example">
        <h3>#{title}</h3>
        <p>#{description}</p>
      </div>
    """

  examplesPageMarkup: (examplesMarkup) ->
    """
      <html>
        <head>
          <title>Facebook App Examples</title>
        </head>
        <body>
          <div id="tw-fb-container">
            <div id="header">
              <img src="/images/teamwork/environments/facebook-text-big.png" />
              <p>Facebook</p>
            </div>
            <div class="examples">
              #{examplesMarkup}
            </div>
          </div>
        </body>
      </html>
    """
