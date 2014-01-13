class AccountAppController extends AppController

  handler = (callback)-> KD.singleton('appManager').open 'Account', callback

  KD.registerAppClass this,
    name                         : "Account"
    routes                       :
      "/:name?/Account"          : -> KD.singletons.router.handleRoute '/Account/Profile'
      "/:name?/Account/:section" : ({params:{section}})-> handler (app)-> app.openSection section
    behavior                     : "hideTabs"
    hiddenHandle                 : yes

  items =
    personal :
      title  : "Personal"
      items  : [
        { slug : 'Profile',   title : "User profile",        listType: "username" }
        { slug : 'Email',     title : "Email notifications", listType: "emailNotifications" }
        { slug : 'Externals', title : "Linked accounts",     listType: "linkedAccounts" }
      ]
    billing :
      title : "Billing"
      items : [
        { slug : "Payment",       title : "Payment methods",     listType: "methods" }
        { slug : "Subscriptions", title : "Your subscriptions",  listType: "subscriptions" }
        { slug : "Billing",       title : "Billing history",     listType: "history" }
      ]
    develop :
      title : "Develop"
      items : [
        { slug : 'SSH',       title : "SSH keys",           listHeader: "Your SSH Keys",          listType: "keys" }
        { slug : 'Keys',      title : "Koding Keys",        listHeader: "Your Koding Keys",       listType: "kodingKeys" }
        { slug : 'Referral',  title : "Referral System",    listHeader: "Your Referral Options",  listType: "referralSystem" }
      ]
    danger  :
      title : "Danger"
      items : [
        { slug: 'Delete', title : "Delete account", listType: "deleteAccount" }
      ]

  constructor:(options={}, data)->

    options.view = new KDView cssClass : "content-page"

    super options, data


  createTab:(itemData)->
    {title, listType} = itemData

    new KDTabPaneView
      view       : new AccountListWrapper
        cssClass : "settings-list-wrapper #{KD.utils.slugify title}"
      , itemData


  openSection:(section)->

    for item in @navController.itemsOrdered when section is item.getData().slug
      @tabView.addPane @createTab item.getData()
      @navController.selectSingleItem item
      break


  loadView:(mainView)->

    # SET UP VIEWS
    @navController = new KDListViewController
      view        : new KDListView
        tagName   : 'aside'
        type      : 'inner-nav'
        itemClass : AccountNavigationItem
      wrapper     : no
      scrollView  : no

    mainView.addSubView navView = @navController.getView()

    mainView.addSubView @tabView = new KDTabView
      hideHandleContainer : yes

    for own sectionKey, section of items
      @navController.instantiateListItems section.items
      navView.addSubView new KDCustomHTMLView tagName : "hr"

    navView.setPartial """
      <a href="/tos.html" target="_blank">Terms of service <span class="icon new-page"></span></a>
      <a href="/privacy.html" target="_blank">Privacy policy <span class="icon new-page"></span></a>
      """

  showReferrerModal:-> new ReferrerModal


  displayConfirmEmailModal:(name, username, callback=noop)->
    name or= KD.whoami().profile.firstName
    message =
      """
      Dear #{name},

      Thanks for joining Koding.<br/><br/>

      You need to confirm your email address to be able to  login Koding and to fully activate your account.

      When you registered, we have sent you a link to confirm your email address, please use that link to be able to continue using Koding.<br/><br/>

      If you didn't receive the email or the token is expired, please click to Resend email button below.<br/><br/>
      """

    modal = new KDModalView
      title            : "Please confirm your email address!"
      width            : 500
      overlay          : yes
      cssClass         : "new-kdmodal"
      content          : "<div class='modalformline'>#{Encoder.htmlDecode message}</div>"
      buttons          :
        "Resend Confirmation Email" :
          style        : "modal-clean-red"
          callback     : => @resendHandler modal, username
        Close          :
          style        : "modal-cancel"
          callback     : => modal.destroy()

    callback modal

  resendHandler : (modal, username)->

    KD.remote.api.JPasswordRecovery.resendVerification username, (err)=>
      modal.buttons["Resend Confirmation Email"].hideLoader()
      return KD.showError err if err
      new KDNotificationView
        title     : "Check your email"
        content   : "We've sent you a confirmation mail."
        duration  : 4500
