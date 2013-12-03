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
        { slug : 'Profile',   title : "User profile",        listType: "username",           listHeader: "Here you can edit your account information." }
        { slug : 'Email',     title : "Email Notifications", listType: "emailNotifications", listHeader: "Email Notifications" }
        { slug : 'Externals', title : "Linked accounts",     listType: "linkedAccounts",     listHeader: "Your Linked Accounts" }
        { slug : 'Referrals', title : "Referrals",           listType: "referralSystem",     listHeader: "Referrals " }
      ]
    billing :
      title : "Billing"
      items : [
        { slug : "Payment",       title : "Payment methods",    listHeader: "Your Payment Methods",       listType: "methods" }
        { slug : "Subscriptions", title : "Your subscriptions", listHeader: "Your Active Subscriptions",  listType: "subscriptions" }
        { slug : "Billing",       title : "Billing history",    listHeader: "Billing History",            listType: "history" }
      ]
    develop :
      title : "Develop"
      items : [
        { slug : 'SSH',  title : "SSH keys",    listHeader: "Your SSH Keys",    listType: "keys" }
        { slug : 'Keys', title : "Koding Keys", listHeader: "Your Koding Keys", listType: "kodingKeys" }
      ]
    danger  :
      title : "Danger"
      items : [
        { slug: 'Delete', title : "Delete Account", listHeader: "Danger Zone", listType: "delete" }
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
        type      : 'account-nav'
        itemClass : AccountNavigationItem
      wrapper     : no
      scrollView  : no

    mainView.addSubView navView = @navController.getView()

    # navView.on 'ItemWasAdded', @bound 'bindItemClickHandler'


    mainView.addSubView @tabView = new KDTabView
      tabHandleContainer : new KDCustomHTMLView

    @tabView.addPane @createTab items.personal.items.first

    for own sectionKey, section of items
      @navController.instantiateListItems section.items
      navView.addSubView new KDCustomHTMLView tagName : "hr"

    navView.setPartial """
      <a href="/tos.html" target="_blank">Terms of service <span class="icon new-page"></span></a>
      <a href="/privacy.html" target="_blank">Privacy policy <span class="icon new-page"></span></a>
      """