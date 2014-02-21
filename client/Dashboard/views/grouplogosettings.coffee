class InlineImageSettings extends KDView

  constructor: (options = {}, data) ->
    options.cssClass or= "group-logo"
    options.type     or= "logo"

    super options, data

    {groupsController} = KD.singletons
    @group = groupsController.getCurrentGroup()

    @imageView = new KDCustomHTMLView
      tagName      : 'figure'
      size         :
        width      : 55
        height     : 55
      attributes   : @getImageViewAttributes()

    @uploadButton  =  new KDButtonView
      cssClass     : "upload-button solid green"
      title        : "Change"
      callback     : @bound "showUploadView"

    @addSubView @imageView
    @addSubView @uploadButton

    @group.on "update", =>
      customizedField = @getCustomized()
      if customizedField
        resized = KD.utils.proxifyUrl customizedField,
          crop     : yes
          width    : 55
          height   : 55
        @imageView.setCss 'background-image', "url(#{resized})"

  showUploadView: ->
    @imageView.hide()
    @uploadButton.hide()

    @addSubView @uploader = new GroupsUploadView
      uploaderOptions :
        cssClass      : "group-#{@getOptions().type}-uploader"
        title         : "#{@getOptions().uploaderTitle}"
        size          :
          width       : 120
          height      : 120

    @uploader.on "UploadCancelled", @bound "revealViews"
    @uploader.on "FileUploadDone",  @bound "handleFileUploadDone"

  revealViews: ->
    @imageView.show()
    @uploadButton.show()

  getImageViewAttributes:->
    fieldToCustomize = @getCustomized()
    if fieldToCustomize
      attributes = {}
      resized    = KD.utils.proxifyUrl fieldToCustomize,
        crop     : yes
        width    : 55
        height   : 55
      attributes =
        style : "background-image: url(#{resized}); background-position: 0 0;"
    else
      @setClass "default"

  getCustomized:->
    imageType = @getOptions().type
    if imageType is "logo"
      return @group.customize?.logo
    if imageType is "favicon"
      return @group.customize?.favicon

  handleFileUploadDone: (url) ->
    @revealViews()
    imageType = @getOptions().type
    if imageType is "logo"
      @group.modify "customize.logo"    : "#{url}"
    if imageType is "favicon"
      @group.modify "customize.favicon" : "#{url}"



