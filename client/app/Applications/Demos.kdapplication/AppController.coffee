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
            sizes       : [ "50%", null ]
            views       : [
              {
                type    : "split"
                options :
                  direction: "horizontal"
                  sizes : [ "50%", null ]
                views   : [
                  {
                    type    : "finder"
                  }
                  {
                    type    : "preview"
                    url     : "http://www.stanford.edu/class/cs101/code-1-introduction.html"
                  }
                ]
              }
              {
                type    : "split"
                options :
                  direction: "horizontal"
                  sizes : [ "50%", null ]
                views   : [
                  {
                    type    : "tabbedEditor"
                  }
                  {
                    type    : "terminal"
                  }
                ]
              }
            ]
          }
        }
      ]