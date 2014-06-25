class StartTabRecentFileItemView extends JView

  constructor:(options = {}, data)->

    options.cssClass or= 'finder-item file clearfix'
    options.tooltip  or=
      title            : "<p class='file-path'>#{FSHelper.plainPath data}</p>"
      template         : '<div class="twipsy-arrow"></div><div class="twipsy-inner twipsy-inner-wide"></div>'

    super options, data

    @loader = new KDLoaderView
      size          :
        width       : 20
      loaderOptions :
        color       : "#ffffff"

    @loader.hide()


  pistachio:->

    path = @getData()
    name = (path.split '/')[(path.split '/').length - 1]
    extension = FSHelper.getFileExtension name
    fileType  = FSHelper.getFileType extension

    """
      <span class='icon #{fileType} #{extension}'></span>
      <span class='title'>#{name}</span>
      {{> @loader}}
    """

  click:(event)->

    path   = @getData()
    file   = FSHelper.createFileInstance { path }

    @loader.show()
    file.fetchContents (err, contents)=>
      @loader.hide()
      if err?.name is "PathError"
        KD.getSingleton("finderController").emit "NoSuchFile", file
        new KDNotificationView
          title     : "#{file.name} is not found."
          type      : "mini"
          duration  : 4000
          cssClass  : "error"
          container : @parent
        @destroy()
      else
        file.contents = contents
        KD.getSingleton("appManager").openFile file
