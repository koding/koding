class LandingPageSideBar extends KDView

  constructor:(isLoggedIn = no)->

    options = lazyDomId : 'landing-page-sidebar'

    super options

    @mainController = @getSingleton "mainController"
    @navController  = new LandingPageNavigationController
      view         : new NavigationList
        itemClass  : LandingNavigationLink
        type       : "navigation"
      scrollView   : no
      wrapper      : no
      delegate     : @
    ,
      items : [
        { title : "Register", action : "register", loggedOut : yes }
        # { type  : "separator" }
        { title : "Logout",   action : "logout",   loggedIn  : yes }
        { title : "Login",    action : "login",    loggedOut : yes }
      ]

    @on 'ListItemsInstantiated' , =>
      $("#profile-static-nav").remove()
      @mainController.emit "AppIsReady"

    @addSubView @nav = @navController.getView()

    @mainController.on "accountChanged.to.*", => @navController.reset()
    @mainController.on "landingSidebarClicked", => @navController.deselectAllItems()


class LandingPageNavigationController extends NavigationController

  reset:->
    view = @getView()
    view.setClass "out"
    @utils.wait 200, =>
      @removeAllItems()
      @instantiateListItems @getData().items
      view.unsetClass "out"

  constructor: ->

    super

    @lc = @getSingleton 'lazyDomController'
    landingPageSideBar = @getDelegate()

    @getListView().on "ItemWasAdded", (item)->
      item.on "click", (event)->
        landingPageSideBar.emit "navItemIsClicked", item, event

  instantiateListItems:(items)->

    items = items.slice()

    # Build groups menu
    if @lc.userEnteredFromGroup()

      {groupEntryPoint} = KD.config

      if KD.isLoggedIn()
        KD.whoami().fetchGroupRoles groupEntryPoint, (err, roles)=>
          if err then console.warn err
          else if roles.length
            @lc.landingView.hide()
            @lc.openPath "/#{if groupEntryPoint is 'koding' then '' else groupEntryPoint+'/'}Activity"
            items.unshift \
              { title: 'Open Group', path: "/#{if groupEntryPoint is 'koding' then '' else groupEntryPoint+'/'}Activity"}
            @_instantiateListItems items
          else
            KD.remote.api.JMembershipPolicy.byGroupSlug groupEntryPoint,
              (err, policy)=>
                if err then console.warn err
                else if policy?.approvalEnabled
                  items.unshift \
                    { title: 'Request access', action: 'request'}
                else
                  items.unshift \
                    { title: 'Join Group', action: 'join-group'}
                @_instantiateListItems items

      else
        items.unshift { title: 'Request access', action: 'request'}

        if groupEntryPoint is "koding" then items.first.title = "Request Invite"

        @_instantiateListItems items

    else if @lc.userEnteredFromProfile()

      profileItems = [
        { title : 'Home',     action : 'home',      type : 'user', selected : yes}
        { title : 'Activity', action : 'activity',  type : 'user'}
        { title : 'About',    action : 'about',     type : 'user'}
      ]

      items = [].concat.apply profileItems, items

      @_instantiateListItems items
    else
      @_instantiateListItems items

  _instantiateListItems:(items)->
    newItems = for itemData in items
      if KD.isLoggedIn()
        continue if itemData.loggedOut
      else
        continue if itemData.loggedIn
      item = @getListView().addItem itemData
    @getDelegate().emit 'ListItemsInstantiated'

class LandingNavigationLink extends NavigationLink

  constructor:(options = {}, data)->

    data.type or= "account"

    super options, data
    @loader = new KDLoaderView
      size :
        width : 20
        height : 20
      loaderOptions :
        color : "#ffffff"
    @loader.hide()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    "<a class='title'><span class='main-nav-icon #{@utils.slugify @getData().title}'></span>#{@getData().title}{{> @loader}}</a>"

  click:->
    @loader.show() if @getData().type is 'user'