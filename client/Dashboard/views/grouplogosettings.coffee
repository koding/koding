class GroupLogoSettings extends KDView
  constructor:(options = {}, data)->
    super options, data

    {groupsController} = KD.singletons
    groupsController.ready =>
      group = groupsController.getCurrentGroup()

      groupLogoView = new KDCustomHTMLView
        tagName     : 'figure'
        size        :
            width   : 55
            height  : 55
        attributes  :
          style     : "background-image: url(#{group.customize?.logo});"
        click       : (event) ->
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

      @addSubView groupLogoView

      group.on "update", ->
        groupLogoView.setCss 'background-image', "url(#{group.customize?.logo})"

  viewAppended:JView::viewAppended
