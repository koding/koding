class GroupsMainView extends KDView

  constructor:(options,data)->
    options = $.extend
      ownScrollBars : yes
    ,options
    super options,data

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Groups"
    header.setSearchInput()

    header.addSubView createGroupButton = new KDButtonView
      title     : "Create a Group"
      style     : "cupid-green create-group-button"
      callback  : ->
        KD.track "Groups", "CreateNewGroupButtonClicked"
        KD.getSingleton('groupsController').showGroupSubmissionView()

    unless KD.isLoggedIn() then createGroupButton.hide()
    KD.singletons.mainController.on "accountChanged.to.loggedIn",
      createGroupButton.bound 'show'