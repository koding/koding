class TeamworkExportModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-modal tw-export-modal confirmation-modal"
    options.title    = ""
    options.overlay  = yes
    options.width    = 655
    options.buttons  =
      Next           :
        cssClass     : "modal-clean-green"
        title        : "Next"
        iconClass    : "tw-next-icon"
        icon         : yes
        callback     : =>
          KD.mixpanel "Teamwork export next, click"
          @startExport()

    super options, data

    @createElements()

  startExport: ->
    @destroySubViews()
    @showLoader()
    @export()

  showLoader: ->
    @loader      = new KDLoaderView
      cssClass   : "export-loader"
      showLoader : yes
      size       :
        width    : 30

    @loader.addSubView new KDCustomHTMLView
      tagName    : "span"
      cssClass   : "loading-text"
      partial    : "Exporting your content. It may take a few minutes depending size of your content. (Max compressed size is 5MB)"

    @addSubView @loader
    @setClass "loading"

  getFileInfo: (fsItem) ->
    fileData = fsItem.getData()
    plain    = FSHelper.plainPath fileData.path
    suffix   = if fileData.type is "folder" then "folder" else "file"

    return """ #{plain.replace("/home/#{KD.nick()}", "~")} #{suffix}"""

  export: ->
    vmController = KD.getSingleton "vmController"
    finderItem   = @getData()
    nodeData     = finderItem.getData()
    tempPath     = "/home/#{KD.nick()}/.tmp"
    {name}       = nodeData

    commands     = [
      "mkdir -p #{tempPath}"
      "cd #{FSHelper.plainPath nodeData.parentPath}"
      "zip -r #{tempPath}/#{nodeData.name}.zip #{name}"
    ]

    vmController.run commands.join("&&"), (err, res) =>
      return warn err  if err
      return warn res.stderr  if res.exitStatus > 0

      file = FSHelper.createFileInstance path: "#{tempPath}/#{name}.zip"
      file.fetchRawContents().then (res) =>
        FSHelper.s3.upload "#{name}.zip", res.content, "user", "", (err, res) =>
          file.remove()
          KD.utils.shortenUrl res, (shorten) =>
            @handleExportDone shorten

  createElements: ->
    KD.mixpanel "Teamwork export, click"
    @addSubView new KDCustomHTMLView
      partial  : """
        <p>
          You are about to pack your #{@getFileInfo @getData()}.
          We will create a link that you can share with others.
        </p>
      """

    @addSubView new KDCustomHTMLView
      cssClass : "tw-share-warning"
      partial  : """
        <span class="warning"></span>
        <p>Be warned, You're exposing your files, make sure that they don't contain information that you don't want to share.</p>
      """

  handleExportDone: (shortenUrl) ->
    @destroy()
    fullUrl      = "#{window.location.origin}/Teamwork?importUrl=#{shortenUrl}"
    inputContent = """
      <div class="join">I exported my files here, click this link to see them.</div>
      <div class="url">#{fullUrl}</div>
    """
    shareWarning = """
      <span class="warning"></span>
      <p>By clicking share this link will be posted publicly on the activity feed. If you just want to send the link privately you can copy the above link.</p>
    """

    new TeamworkShareModal { inputContent, shareWarning }
