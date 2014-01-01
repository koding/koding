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
    # develop :
    #   title : "Develop"
    #   items : [
    #     { slug : 'SSH',  title : "SSH keys",    listHeader: "Your SSH Keys",    listType: "keys" }
    #     { slug : 'Keys', title : "Koding Keys", listHeader: "Your Koding Keys", listType: "kodingKeys" }
    #   ]
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
