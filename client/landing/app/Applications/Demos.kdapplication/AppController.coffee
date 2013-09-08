class DemosAppController extends AppController

  KD.registerAppClass this,
    name         : "Demos"
    route        : "/Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->
    mainView.addSubView new CollaborativeWorkspace
      firebaseInstance  : "teamwork-local"
      enableChat        : yes
      panels            : [
        {
          title         : "Collaborative Preview Pane"
          hint          : "Huloggg"
          buttons       : [
            {
              title     : "Join"
              cssClass  : "cupid-green join-button"
              callback  : (panel, workspace) => workspace.showJoinModal()
            }
          ]
          layout        : {
            direction   : "vertical"
            sizes       : [ "100%", null ]
            views   : [
              {
                type    : "drawing"
              }
              {
                type: "preview"
              }
            ]
          }
        }
      ]