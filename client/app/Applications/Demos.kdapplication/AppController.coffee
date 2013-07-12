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
      name               : "Teamwork"
      version            : "0.1"
      joinModalTitle     : "Join a coding session"
      joinModalContent   : "<p>Paste the session key that you received and start coding together.</p>"
      shareSessionKeyInfo: "<p>This is your session key, you can share this key with your friends to work together.</p>"
      firebaseInstances  : "teamwork-local"
      # firebaseInstances  : ["kd-prod-1", "kd-prod-2", "kd-prod-3", "kd-prod-4", "kd-prod-5"]
      panels             : [
        {
          title          : "Teamwork"
          hint           : "<p>This is a collaborative coding environment where you can team up with others and work on the same code.</p>"
          buttons        : [
            {
              title      : "Join"
              cssClass   : "cupid-green join-button"
              callback   : (panel, workspace) => workspace.showJoinModal()
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
