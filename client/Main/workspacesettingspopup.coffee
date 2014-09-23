class WorkspaceSettingsPopup extends KDModalViewWithForms

  constructor:(options = {}, data = {})->

    options             = KD.utils.extend options,
      title             : "Workspace settings"
      cssClass          : 'activity-modal vm-settings'
      content           : ""
      overlay           : yes
      width             : 335
      height            : 'auto'
      arrowTop          : no
      tabs              : forms: Settings: fields:
        guides          :
          label         : "Related Guides"
          itemClass     : GuidesLinksView

    super options, data

  viewAppended:->

    @addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete Workspace'
      callback : =>
        alert "delete"
        KD.singletons.computeController.destroy @machine
        @destroy()
