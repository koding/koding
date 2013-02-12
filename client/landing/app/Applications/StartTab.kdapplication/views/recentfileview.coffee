class StartTabRecentFileItemView extends JView

  constructor:(options = {}, data)->

    options.cssClass or= 'finder-item file clearfix'
    options.tooltip  or=
      title            : "<p class='file-path'>#{data}</p>"
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
    extension = __utils.getFileExtension name
    fileType  = __utils.getFileType extension

    """
      <span class='icon #{fileType} #{extension}'></span>
      <span class='title'>#{name}</span>
      {{> @loader}}
    """

  click:(event)->

    # KD.getSingleton("appManager").notify()
    file = FSHelper.createFileFromPath @getData()
    @loader.show()
    file.fetchContents (err, contents)=>
      @loader.hide()
      if err
        if /No such file or directory/.test err
          @getSingleton('mainController').emit "NoSuchFile", file
          new KDNotificationView
            title     : "This file is deleted in server!"
            type      : "mini"
            container : @parent
            cssClass  : "error"
      else
        file.contents = contents
        KD.getSingleton("appManager").openFile file
