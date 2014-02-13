class GroupLogoSettings extends KDView

  constructor: (options = {}, data) ->

    options.cssClass   = "group-logo"

    super options, data

    {groupsController} = KD.singletons
    @group = groupsController.getCurrentGroup()

    attributes    = {}
    if @group.customize?.logo
      proxifyOptions =
        crop         : yes
        width        : 55
        height       : 55
      resized = KD.utils.proxifyUrl @group.customize.logo, proxifyOptions
      log "resized",resized
      attributes  =
        style     : "background-image: url(#{resized});"
    else
      @setClass "default"

    @groupLogoView = new KDCustomHTMLView
      tagName      : 'figure'
      size         :
        width      : 55
        height     : 55
      attributes   : attributes

    @uploadButton  =  new KDButtonView
      cssClass     : "upload-button solid green"
      title        : "Change"
      callback     : @bound "showUploadView"

    @addSubView @groupLogoView
    @addSubView @uploadButton

    @group.on "update", =>
      @groupLogoView.setCss 'background-image', "url(#{@group.customize?.logo})"

  showUploadView: ->
    @groupLogoView.hide()
    @uploadButton.hide()

    @addSubView @uploader = new GroupsUploadView
      uploaderOptions :
        cssClass      : "group-logo-uploader"
        title         : "Drop your new logo here!"
        size          :
          width       : 120
          height      : 80

    @uploader.on "UploadCancelled", @bound "revealViews"
    @uploader.on "FileUploadDone",  @bound "handleFileUploadDone"

  revealViews: ->
    @groupLogoView.show()
    @uploadButton.show()

  handleFileUploadDone: (url) ->
    @revealViews()
    @group.modify "customize.logo" : "#{url}?#{Date.now()}"
