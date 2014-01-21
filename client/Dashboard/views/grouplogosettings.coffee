class GroupLogoSettings extends KDView
  constructor:(options = {}, data)->
    super options, data

    @groupLogoView = new KDCustomHTMLView
      tagName     : 'img'
      size        :
          width   : 55
          height  : 55
      attributes  :
        src       : ""
      click       : (event) =>
        new UploadImageModalView
          title         : "Change Group Logo"
          imageType     : "logo"
          imageSize     :
            width       : 55
            height      : 55
          previewSize   :
            width       : 220
            height      : 220

  pistachio:->
      """
      {{> @groupLogoView}}
      """

  viewAppended:JView::viewAppended
