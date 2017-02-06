globals = require 'globals'
checkFlag = require './util/checkFlag'
kd = require 'kd'
whoami = require './util/whoami'
MembershipRoleChangedModal =  require 'app/components/membershiprolechangedmodal'


module.exports = class MainViewController extends kd.ViewController

  logViewByElement = (el) ->

    for __, view of kd.instances when view.getElement?
      if el is view.getElement()
        kd.log view
        break

    logViewByElement el.parentNode  unless el.parentNode is global.document.body


  constructor: ->

    super

    mainView             = @getView()
    appManager           = kd.singleton 'appManager'

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane

    appManager.on 'AppIsBeingShown', (controller) =>
      { customName, name } = controller.getOptions()
      @setBodyClass kd.utils.slugify customName ? name

    if globals.config?.environment isnt 'production'
      global.addEventListener 'click', (event) ->
        if event.metaKey and event.altKey
          logViewByElement event.target
      , yes

    { groupsController } = kd.singletons

    groupsController.ready ->
      groupsController.on 'MembershipRoleChanged', (data) ->
        { reactor } = kd.singletons
        { contents: { role, id, adminNick } } = data
        reactor.dispatch 'UPDATE_TEAM_MEMBER_WITH_ID', { id, role }

        if id is whoami()._id
          modal = new MembershipRoleChangedModal
            success: ->
              modal.destroy()
              global.location.reload yes
          , { role, adminNick }



  loadView: (mainView) ->

    mainView.ready ->

      { body } = global.document
      if checkFlag 'super-admin'
      then kd.View.setElementClass body, 'add', 'super'
      else kd.View.setElementClass body, 'remove', 'super'


  setBodyClass: do ->

    previousClass = null

    (name) ->

      { body } = global.document
      kd.View.setElementClass body, 'remove', previousClass  if previousClass
      kd.View.setElementClass body, 'add', name
      previousClass = name


  mainTabPaneChanged: (mainView, pane) ->

    appManager      = kd.getSingleton 'appManager'
    { mainTabView } = mainView

    if pane
    then @setViewState pane.getOptions()
    else mainTabView.getActivePane().show()


  setViewState: (options = {}) ->

    { behavior, name } = options

    html     = global.document.documentElement
    mainView = @getView()

    fullSizeApps    = [ 'content-display' ]
    appsWithSidebar = [ 'content-display', 'Dashboard', 'Stackeditor' ]

    if (isApp = behavior is 'application') or (name in fullSizeApps)
    then kd.View.setElementClass html, 'add', 'app'
    else kd.View.setElementClass html, 'remove', 'app'

    if isApp or name in appsWithSidebar
    then mainView.setClass 'with-sidebar'
    else mainView.unsetClass 'with-sidebar'
