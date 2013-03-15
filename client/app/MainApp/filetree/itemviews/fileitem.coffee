class NFileItemView extends KDCustomHTMLView

  constructor:(options = {},data)->

    options.tagName   or= "div"
    options.cssClass  or= "file"
    super options, data
    fileData = @getData()

    @loader = new KDLoaderView
      size          :
        width       : 16
      loaderOptions :
        # color       : @utils.getRandomHex()
        color       : "#222222"
        shape       : "spiral"
        diameter    : 16
        density     : 30
        range       : 0.4
        speed       : 1.5
        FPS         : 24

    @icon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "icon"

    data.on "fs.*.started", => @showLoader()
    data.on "fs.*.finished", => @hideLoader()

    # data.on "fs.saveAs.finished", (newFile, oldFile)=>
    #   oldFile.emit "folderNeedsToRefresh", newFile

  destroy:->

    @getData().off "fs.*.started"
    @getData().off "fs.*.finished"
    @getData().off "fs.saveAs.finished"
    super

  decorateItem:->

    extension = FSItem.getFileExtension @getData().name
    if extension
      fileType = FSItem.getFileType extension
      @icon.$().attr "class", "icon #{extension} #{fileType}"

  render:->

    super
    @decorateItem()

  mouseDown:-> yes

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @hideLoader()
    @decorateItem()

  showLoader:->

    @parent?.isLoading = yes
    @icon.hide()
    @loader.show()

  hideLoader:->

    @parent?.isLoading = no
    @icon.show()
    @loader.hide()


  pistachio:->

    """
      {{> @icon}}
      {{> @loader}}
      {span.title{ #(name)}}
      <span class='chevron'></span>
    """