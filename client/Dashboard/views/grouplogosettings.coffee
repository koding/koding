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
          title      : "Change Group Logo"
          image      :
            type     : "logo"
            size     :
              width  : 55
              height : 55
          preview    :
            size     :
              width  : 220
              height : 220

  pistachio:->
    """
    {{> @groupLogoView}}
    """

  viewAppended:JView::viewAppended
