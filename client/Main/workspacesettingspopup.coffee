class WorkspaceSettingsPopup extends KDModalViewWithForms

  constructor:(options = {}, data)->

    options         = KD.utils.extend options,
      title         : "Workspace settings"
      cssClass      : 'activity-modal ws-settings'
      content       : ""
      overlay       : yes
      width         : 268
      height        : 'auto'
      arrowTop      : no
      tabs          : forms: Settings: fields:
        guides      :
          label     : "Related Guides"
          itemClass : GuidesLinksView

    super options, data

  viewAppended:->

    navItem   = @getData()
    workspace = navItem.getData()

    @addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete Workspace'
      callback : =>
        alert "delete"
        @destroy()

    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 34
