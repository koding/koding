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
showError             = require 'app/util/showError'
oauthEnabled          = require 'app/util/oauthEnabled'
AppController         = require 'app/appcontroller'
Encoder               = require 'htmlencode'
require('./routehandler')()


module.exports = class AccountAppController extends AppController

  @options =
    name  : 'Account'

  items =
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
        # { slug : 'Referral',    title : "Referral System",    listHeader: "Your Referral Options",  listType: "referralSystem" }
        # { slug : 'Credentials', title : "Credentials",        listHeader: "Your Credentials",       listType: "credentials" }
      ]
    danger  :
      title : "Danger"
      items : [
        { slug: 'Delete', title : "Delete account", listType: "deleteAccount" }
      ]


  if oauthEnabled() is yes
    items.personal.items.push({ slug : 'Externals', title : "Linked accounts",     listType: "linkedAccounts" })

  constructor:(options={}, data)->

    options.view = new KDModalView
      title    : 'Account Settings'
      cssClass : 'AppModal AppModal--account'
      width    : 805

    super options, data


  createTab: (itemData) ->

    {title, listType} = itemData

    new KDTabPaneView
      view       : new AccountListWrapper
        cssClass : "settings-list-wrapper #{kd.utils.slugify title}"
      , itemData


  openSection: (section) ->

    for item in @navController.getListItems() when section is item.getData().slug
      @tabView.addPane @createTab item.getData()
      @navController.selectItem item
      break


  loadView: (modal) ->

    # SET UP VIEWS
    @navController = new KDListViewController
      view        : new KDListView
        tagName   : 'nav'
        type      : 'inner-nav'
        itemClass : AccountNavigationItem
      wrapper     : no
      scrollView  : no

    mainView.addSubView aside = new KDView
      tagName   : 'aside'
      cssClass  : 'AppModal-nav'

    aside.addSubView navView = @navController.getView()

    mainView.addSubView appContent = new KDCustomHTMLView
      cssClass            : 'AppModal-content'

    appContent.addSubView @tabView = new KDTabView
      hideHandleContainer : yes

    for own sectionKey, section of items
      @navController.instantiateListItems section.items
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


  showRegistrationNeededModal: ->

    return if @modal

    handler = (modal, route) ->

      modal.destroy()
      kd.utils.wait 1000, -> kd.getSingleton("router").handleRoute route

    @modal = new KDBlockingModalView
      title           : "Please Login or Register"
      content : """
      Every Koding user gets a private virtual machine with root access. Let's give you one in 10 seconds so that you can
      code, collaborate and have fun! :)
      <br><br>
      <iframe width="560" height="315" src="//www.youtube.com/embed/MZOpD8mdFVc" frameborder="0" allowfullscreen></iframe>
      <br><br>
      Click play to see what Koding is all about in 2 minutes!
      """
      width           : 660
      overlay         : yes
      buttons         :
        "Login"       :
          style       : "solid light-gray medium"
          callback    : => handler @modal, "/Login"
        "Register"    :
          style       : "solid light-gray medium"
          callback    : => handler @modal, "/Register"


    @modal.on "KDObjectWillBeDestroyed", => @modal = null
