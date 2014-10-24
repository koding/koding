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
          links     : "Understanding Workspaces" : "http://learn.koding.com/guides/getting-started/workspaces/"

    super options, data

  viewAppended:->

    navItem   = @getData()
    workspace = navItem.getData()

    @addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete Workspace'
      callback : =>

        KD.remote.api.JWorkspace.deleteById workspace.id, (err)=>

          return  if KD.showError err

          navItem.destroy()
          @destroy()

          KD.singletons
            .router.handleRoute "/IDE/#{workspace.machineLabel}/my-workspace"


    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 34
