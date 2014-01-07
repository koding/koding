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
        callback     : => @startExport()

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
      partial    : "Exporting your content"

    @addSubView @loader

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
      file = FSHelper.createFileFromPath "#{tempPath}/#{name}.zip"
      file.fetchContents (err, contents) =>
        FSHelper.s3.upload "#{name}.zip", btoa(contents), (err, res) =>
          file.remove ->
          KD.utils.shortenUrl res, (shorten) =>
            @handleExportDone shorten
      , no

  createElements: ->
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
    inputContent = """
      <div class="join">I exported my files here, click this link to see them.</div>
      <div class="url">https://koding.com/Teamwork?importUrl=#{shortenUrl}</div>
    """
    modal     = new TeamworkShareModal { inputContent, addShareWarning: no }
    container = new KDCustomHTMLView
      cssClass: "tw-export-settings"

    container.addSubView new KodingSwitch
      cssClass      : "dark tw-export-switch"
      defaultValue  : "off"
      callback      : (state) ->
        if state
          modal.destroy()
          new TeamworkExportedUrlModal {}, shortenUrl

    container.addSubView new KDCustomHTMLView
      tagName       : "span"
      partial       : "Don't share on Koding Activity, just give me a link"
      cssClass      : "tw-export-text"

    modal.addSubView container


class TeamworkExportedUrlModal extends KDModalView

  constructor: (options = {}, data) ->

    options.content  = "<p>Here is the link that you can share with others</p>"
    options.cssClass = "tw-url-modal tw-modal"
    options.overlay  = yes
    options.width    = 600
    options.buttons  =
      Done           :
        cssClass     : "modal-clean-green"
        title        : "Done"
        callback     : => @destroy()

    super options, data

    @addSubView new KDInputView
      defaultValue : data
      cssClass     : "url-input"
      attributes   :
        readonly   : "readonly"
      click        : -> @selectAll()