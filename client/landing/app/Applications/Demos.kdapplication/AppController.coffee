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
    options =
      title              : "Kodelicious"
      version            : "0.1"
      joinModalContent   : "<p>Here is the join modal</p>"
      shareModalContent  : "<p>Here is the share modal</p>"
      firebaseInstances  : "teamwork-local"
      # firebaseInstances  : ["kd-prod-1", "kd-prod-2", "kd-prod-3", "kd-prod-4", "kd-prod-5"]
      panels             : [
        {
          title          : "Collaborative IDE"
          hint           : "<p>This is the Collaborative IDE that you ever dreamed. Use it wisely.</p>"
          buttons        : [
            {
              title      : "Join"
              cssClass   : "cupid-green join-button"
              callback   : (panel, workspace) => workspace.showJoinModal()
            }
            {
              title      : "Share"
              callback   : (panel, workspace) => workspace.showShareModal()
            }
          ]
          panes: [
            {
              type  : "finder"
            }
            {
              type  : "tabbedEditor"
            }
            {
              type  : "terminal"
            }
          ]
        }
      ]
    kolab = new CollaborativeWorkspace options
    kolab.on "PanelCreated", =>
      kolab.activePanel.splitView.resizePanel "20%", 0
    mainView.addSubView kolab
