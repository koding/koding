kd                    = require 'kd'
KDBlockingModalView   = kd.BlockingModalView
KDCustomHTMLView      = kd.CustomHTMLView
KDListView            = kd.ListView
KDListViewController  = kd.ListViewController
KDModalView           = kd.ModalView
KDNotificationView    = kd.NotificationView
KDTabPaneView         = kd.TabPaneView
KDTabView             = kd.TabView
KDView                = kd.View
remote                = require('app/remote').getInstance()
AccountListWrapper    = require './accountlistwrapper'
AccountNavigationItem = require './accountnavigationitem'
ReferrerModal         = require './views/referrermodal'
whoami                = require 'app/util/whoami'
checkFlag             = require 'app/util/checkFlag'
showError             = require 'app/util/showError'
oauthEnabled          = require 'app/util/oauthEnabled'
AppController         = require 'app/appcontroller'
Encoder               = require 'htmlencode'
require('./routehandler')()


module.exports = class AccountAppController extends AppController

  @options =
    name       : 'Account'
    background : yes

  NAV_ITEMS =
    personal :
      title  : "Personal"
      items  : [
        { slug : 'Profile',   title : "User profile",        listType: "username" }
        { slug : 'Email',     title : "Email notifications", listType: "emailNotifications" }
      ]
    billing :
      title : "Billing"
      items : [
        { slug : "Billing", title : "Billing", listType: "billing" }
      ]
    develop :
      title : "Develop"
      items : [
        { slug : 'SSH',         title : "SSH keys",           listHeader: "Your SSH Keys",          listType: "keys" }
        # { slug : 'Keys',        title : "Koding Keys",        listHeader: "Your Koding Keys",       listType: "kodingKeys" }
        { slug : 'Referral',    title : "Referral System",    listHeader: "Your Referral Options",  listType: "referralSystem" }
        { slug : 'Shortcuts', title : 'Shortcuts',           listType: 'shortcuts' }
      ]
    danger  :
      title : "Danger"
      items : [
        { slug: 'Delete', title : "Delete account", listType: "deleteAccount" }
      ]


  if oauthEnabled() is yes
    NAV_ITEMS.personal.items.push { slug : 'Externals',   title : "Linked accounts", listType: "linkedAccounts" }

  constructor: (options = {}, data) ->

    options.view = new KDModalView
      title    : 'Account Settings'
      cssClass : 'AppModal AppModal--account'
      width    : 805
      overlay  : yes

    super options, data


  createTab: (itemData) ->

    {title, listType} = itemData

    wrapper = new AccountListWrapper
      cssClass : "settings-list-wrapper #{kd.utils.slugify title}"
    , itemData

    wrapper.on 'ModalCloseRequested', @bound 'closeModal'

    new KDTabPaneView view : wrapper

  closeModal: ->

    @mainView.destroy()

  openSection: (section) ->

    for item in @navController.getListItems() when section is item.getData().slug
      @tabView.addPane @createTab item.getData()
      @navController.selectItem item
      break


  loadView: (modal) ->

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

    aside.addSubView navView = @navController.getView()

    modal.addSubView appContent = new KDCustomHTMLView
      cssClass            : 'AppModal-content'

    appContent.addSubView @tabView = new KDTabView
      hideHandleContainer : yes

    items = []
    for own sectionKey, section of NAV_ITEMS
      items = items.concat section.items

    # Temporary solution to hide this from other users ~ GG
    if checkFlag 'super-admin'
      items.push { slug : 'Credentials', title : "Credentials", listHeader: "Your Credentials", listType: "credentials" }

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


  displayConfirmEmailModal: (name, username, callback=kd.noop) ->

    name or= whoami().profile.firstName
    message =
      """
      You need to confirm your email address to continue using Koding and to fully activate your account.<br/><br/>

      When you registered, we sent you a link to confirm your email address. Please use that link.<br/><br/>

      If you had trouble with the email, please click below to resend it.<br/><br/>
      """

    modal = new KDModalView
      title            : "#{name}, please confirm your email address!"
      width            : 600
      overlay          : yes
      cssClass         : "new-kdmodal"
      content          : "<div class='modalformline'>#{Encoder.htmlDecode message}</div>"
      buttons          :
        "Resend Confirmation Email" :
          style        : "solid green medium"
          callback     : => @resendHandler modal, username
        Close          :
          style        : "solid light-gray medium"
          callback     : -> modal.destroy()

    callback modal


  resendHandler : (modal, username) ->

    remote.api.JPasswordRecovery.resendVerification username, (err)=>
      modal.buttons["Resend Confirmation Email"].hideLoader()
      return showError err if err
      new KDNotificationView
        title     : "Check your email"
        content   : "We've sent you a confirmation mail."
        duration  : 4500
