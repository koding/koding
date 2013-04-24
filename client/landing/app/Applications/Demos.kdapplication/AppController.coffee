class DemosAppController extends AppController

  KD.registerAppClass @,
    name         : "Demos"
    route        : "Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->
    mainView.addSubView new KDHeaderView
      title : 'Demo App'

    chatListView   = new ChatContactListView
    chatController = new ChatContactListController
      view : chatListView
    chatController.loadItems()

    mainView.addSubView chatListView