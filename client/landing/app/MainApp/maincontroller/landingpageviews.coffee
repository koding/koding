
class LandingPageSideBar extends KDView

  constructor:(isLoggedIn = no)->

    options     =
      lazyDomId : 'landing-page-sidebar'

    super options

    @navController = new LandingPageNavigationController
      view         : new NavigationList
        itemClass  : LandingPageNavigationLink
        type       : "navigation"
      scrollView   : no
      wrapper      : no
    ,
      items : [
        { title : "Register", action : "register", loggedOut : yes }
        { type  : "separator" }
        { title : "Logout",   action : "logout",   loggedIn  : yes }
        { title : "Login",    action : "login",    loggedOut : yes }
      ]

    @addSubView @nav = @navController.getView()

class LandingPageNavigationController extends NavigationController

  constructor: ->
    super

    @lc = @getSingleton 'lazyDomController'

  instantiateListItems:(items)->

    # Build groups menu
    if @lc.userEnteredFromGroup

      {groupEntryPoint} = KD.config

      if KD.isLoggedIn()
        KD.whoami().fetchGroupRoles groupEntryPoint, (err, roles)=>
          if err then console.warn err
          else if roles.length
            items.unshift \
              { title: 'Open Group', path: "/#{groupEntryPoint}/Activity"}
            @_instantiateListItems items
          else
            KD.remote.api.JMembershipPolicy.byGroupSlug groupEntryPoint,
              (err, policy)=>
                if err then console.warn err
                else if policy?.approvalEnabled
                  items.unshift \
                    { title: 'Request to Join', action: 'request'}
                else
                  items.unshift \
                    { title: 'Join Group', action: 'join-group'}
                @_instantiateListItems items

      else
        items.unshift { title: 'Request to Join', action: 'request'}
        @_instantiateListItems items

    else
      @_instantiateListItems items

  _instantiateListItems:(items)->
    newItems = for itemData in items
      if KD.isLoggedIn()
        continue if itemData.loggedOut
      else
        continue if itemData.loggedIn
      @getListView().addItem itemData

class LandingPageNavigationLink extends NavigationLink

  constructor:(options = {}, data)->
    data.type or= "account"
    super options, data

  click:(event)->
    {action, appPath, title, path, type} = @getData()
    log "here", @getData()

    {loginScreen} = @getSingleton 'mainController'

    switch action
      when 'login'
        loginScreen.animateToForm 'login'
      when 'register'
        loginScreen.animateToForm 'register'
      when 'request'
        loginScreen.animateToForm 'lr'
