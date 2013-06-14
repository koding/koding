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
    extension = FSItem.getFileExtension name
    fileType  = FSItem.getFileType extension

    """
      <span class='icon #{fileType} #{extension}'></span>
      <span class='title'>#{name}</span>
      {{> @loader}}
    """

  click:(event)->

    path = @getData()

    vmName = FSHelper.getVMNameFromPath path
    path   = FSHelper.plainPath path
    file   = FSHelper.createFile {path, vmName, type:'file'}

    @loader.show()
    file.fetchContents (err, contents)=>
      @loader.hide()
      if err
        if /No such file or directory/.test err
          KD.getSingleton('mainController').emit "NoSuchFile", file
          new KDNotificationView
            title     : "This file is deleted in server!"
            type      : "mini"
            container : @parent
            cssClass  : "error"
      else
        file.contents = contents
        KD.getSingleton("appManager").openFile file
