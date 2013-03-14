
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
        { title : "Register",        action : "register", loggedOut : yes }
        { type  : "separator" }
        { title : "Logout",          action : "logout",   loggedIn  : yes }
        { title : "Login",           action : "login",    loggedOut : yes }
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


class LandingPageNavigationLink extends KDListItemView

  constructor:(options = {},data)->

    data.type      or= ""
    options.cssClass = KD.utils.curryCssClass "navigation-item clearfix account"#, data.type

    super options,data

    @name = data.title

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

  partial:(data)->
    "<a class='title'><span class='main-nav-icon #{@utils.slugify data.title}'></span>#{data.title}</a>"

# switchGroupState:(isLoggedIn)->

#   {groupEntryPoint} = KD.config

#   loginLink = new GroupsLandingPageButton {groupEntryPoint}, {}

#   if isLoggedIn and groupEntryPoint?
#     KD.whoami().fetchGroupRoles groupEntryPoint, (err, roles)->
#       if err then console.warn err
#       else if roles.length
#         loginLink.setState { isMember: yes, roles }
#       else
#         {JMembershipPolicy} = KD.remote.api
#         JMembershipPolicy.byGroupSlug groupEntryPoint,
#           (err, policy)->
#             if err then console.warn err
#             else if policy?
#               loginLink.setState {
#                 isMember        : no
#                 approvalEnabled : policy.approvalEnabled
#               }
#             else
#               loginLink.setState {
#                 isMember        : no
#                 isPublic        : yes
#               }
#   else
#     @utils.defer -> loginLink.setState { isLoggedIn: no }

#   loginLink.appendToSelector '.group-login-buttons'
