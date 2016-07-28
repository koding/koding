kd                    = require 'kd'
KDView                = kd.View
remote                = require('app/remote').getInstance()
whoami                = require 'app/util/whoami'
Encoder               = require 'htmlencode'
isKoding              = require 'app/util/isKoding'
KDTabView             = kd.TabView
checkFlag             = require 'app/util/checkFlag'
showError             = require 'app/util/showError'
KDListView            = kd.ListView
KDModalView           = kd.ModalView
KDTabPaneView         = kd.TabPaneView
AppController         = require 'app/appcontroller'
ReferrerModal         = require './views/referrermodal'
KDCustomHTMLView      = kd.CustomHTMLView
AccountListWrapper    = require './accountlistwrapper'
KDNotificationView    = kd.NotificationView
KDListViewController  = kd.ListViewController
AccountNavigationItem = require './accountnavigationitem'
require('./routehandler')()

module.exports = class AccountAppController extends AppController

  @options =
    name       : 'Account'
    background : yes


  kodingDangerItems = [ { slug: 'Delete', title : 'Delete account', listType: 'deleteAccount' } ]
  teamsDangerItems  = [ { slug: 'Leave',  title : 'Leave team',     listType: 'leaveGroup' } ]

  NAV_ITEMS =
    personal :
      title  : 'Personal'
      items  : [
        { slug : 'Profile',       title : 'User profile',        listType: 'username' }
        { slug : 'TwoFactorAuth', title : '2-Factor Auth',       listType: 'twofactorauth', listHeader: 'Two-Factor Authentication' }
        { slug : 'Email',         title : 'Email notifications', listType: 'emailNotifications' }
        { slug : 'Externals',     title : 'Linked accounts',     listType: 'linkedAccounts' }
        { slug : 'Sessions',      title : 'Active Sessions',     listType: 'sessions' }
      ]
    billing :
      title : 'Billing'
      items : [
        { slug : 'Billing', title : 'Billing', listType: 'billing' }
      ]
    develop :
      title : 'Develop'
      items : [
        { slug : 'SSH',       title : 'SSH keys',    listHeader: 'Your SSH Keys',          listType: 'keys' }
        # { slug : 'Keys',      title : 'Koding Keys', listHeader: 'Your Koding Keys',       listType: 'kodingKeys' }
        { slug : 'Referral',  title : 'Referrals',   listHeader: 'Your Referral Options',  listType: 'referralSystem' }
        { slug : 'Shortcuts', title : 'Shortcuts',   listType: 'shortcuts' }
      ]
    danger  :
      title : 'Danger'
      items : []


  constructor: (options = {}, data) ->

    options.view = new KDModalView
      title    : 'Account Settings'
      cssClass : 'AppModal AppModal--account'
      width    : 805
      overlay  : yes

    super options, data


  createTab: (itemData) ->

    { title, listType } = itemData

    wrapper = new AccountListWrapper
      cssClass : "settings-list-wrapper #{kd.utils.slugify title}"
    , itemData

    wrapper.on 'ModalCloseRequested', @bound 'closeModal'

    new KDTabPaneView { view : wrapper }

  closeModal: ->

    @mainView.destroy()

  openSection: (section, query) -> kd.singletons.mainController.ready =>

    if section is 'Oauth' and query.provider?
      @handleOauthRedirect query
      return

    for item in @navController.getListItems() when section is item.getData().slug
      @tabView.addPane @createTab item.getData()
      @navController.selectItem item
      break


  handleOauthRedirect: (options) ->

    { error, provider } = options

    error = null  if error is 'null'
    kd.singletons.oauthController.authCompleted error, provider

    kd.singletons.router.handleRoute '/Account/Externals',
      shouldPushState : yes
      replaceState    : yes


  loadView: (modal) -> kd.singletons.mainController.ready =>

    @navController?.destroy()
    @navController = new KDListViewController
      view        : new KDListView
        tagName   : 'nav'
        type      : 'inner-nav'
        itemClass : AccountNavigationItem
      wrapper     : no
      scrollView  : no

    modal.addSubView aside = new KDView
      tagName   : 'aside'
      cssClass  : 'AppModal-nav'

    aside.addSubView @navController.getView()

    modal.addSubView appContent = new KDCustomHTMLView
      cssClass            : 'AppModal-content'

    appContent.addSubView @tabView = new KDTabView
      hideHandleContainer : yes

    groupSlug  = kd.singletons.groupsController.getGroupSlug()
    items = []

    NAV_ITEMS.danger.items = if isKoding() then kodingDangerItems else teamsDangerItems

    for own __, section of NAV_ITEMS
      mergeables = []
      for item in section.items
        if groupSlug is 'koding'
          mergeables = section.items
        else
          mergeables.push item  unless item.slug in [ 'Billing', 'Referral', 'Delete' ]

      items = items.concat mergeables

    # Temporary solution to hide this from other users ~ GG
    if checkFlag('super-admin') or not isKoding()
      items.push { slug : 'Credentials',  title : 'Your credentials',  listHeader: 'Your Credentials',  listType: 'credentials' }

    @navController.instantiateListItems items

    modal.once 'KDObjectWillBeDestroyed', ->
      { router } = kd.singletons
      previousRoutes = router.visitedRoutes.filter (route) -> not /^\/Account.*/.test(route)
      if previousRoutes.length > 0
      then router.handleRoute previousRoutes.last
      else router.handleRoute router.getDefaultRoute()


  showReferrerModal: (options = {}) ->

    return  if @referrerModal and not @referrerModal.isDestroyed

    options.top         ?= 50
    options.left        ?= 35
    options.arrowMargin ?= 110

    @referrerModal = new ReferrerModal options


  displayConfirmEmailModal: (name, username, callback = kd.noop) ->

    name or= whoami().profile.firstName
    message =
      '''
      You need to confirm your email address to continue using Koding and to fully activate your account.<br/><br/>

      When you registered, we sent you a link to confirm your email address. Please use that link.<br/><br/>

      If you had trouble with the email, please click below to resend it.<br/><br/>
      '''

    modal = new KDModalView
      title            : "#{name}, please confirm your email address!"
      width            : 600
      overlay          : yes
      cssClass         : 'new-kdmodal'
      content          : "<div class='modalformline'>#{Encoder.htmlDecode message}</div>"
      buttons          :
        'Resend Confirmation Email' :
          style        : 'solid green medium'
          callback     : => @resendHandler modal, username
        Close          :
          style        : 'solid light-gray medium'
          callback     : -> modal.destroy()

    callback modal


  resendHandler : (modal, username) ->

    remote.api.JPasswordRecovery.resendVerification username, (err) ->
      modal.buttons['Resend Confirmation Email'].hideLoader()
      return showError err if err
      new KDNotificationView
        title     : 'Check your email'
        content   : "We've sent you a confirmation mail."
        duration  : 4500
