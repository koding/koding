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
