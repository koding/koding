class AccountAppController extends AppController

  KD.registerAppClass this,
    name         : "Account"
    route        : "/:name?/Account"
    behavior     : "hideTabs"
    hiddenHandle : yes
    # navItem      :
    #   title      : "Account"
    #   path       : "/Account"
    #   order      : 70
    #   type       : "account"
    #   loggedIn   : yes

  items =
    personal :
      title : "Personal"
      items : [
        { title : "Login & Email",        listHeader: "Email & username",           listType: "username",       id : 10,      parentId : null }
        { title : "Password & Security",  listHeader: "Password & Security",        listType: "security",       id : 20,      parentId : null }
        { title : "Email Notifications",  listHeader: "Email Notifications",        listType: "emailNotifications", id : 22,  parentId : null }
        { title : "Linked accounts",      listHeader: "Your Linked Accounts",       listType: "linkedAccounts", id : 30,      parentId : null }
        { title : "Referrals",            listHeader: "Referrals ",                 listType: "referralSystem", id : 40,      parentId : null }
      ]
    billing :
      title : "Billing"
      items : [
        { title : "Payment methods",      listHeader: "Your Payment Methods",       listType: "methods",        id : 10,      parentId : null }
        { title : "Your subscriptions",   listHeader: "Your Active Subscriptions",  listType: "subscriptions",  id : 20,      parentId : null }
        { title : "Billing history",      listHeader: "Billing History",            listType: "history",        id : 30,      parentId : null }
      ]
    develop :
      title : "Develop"
      items : [
        { title : "SSH keys",             listHeader: "Your SSH Keys",              listType: "keys",           id : 5,       parentId : null }
        { title : "Koding Keys",          listHeader: "Your Koding Keys",           listType: "kodingKeys",     id : 10,      parentId : null }
      ]
    danger  :
      title : "Danger"
      items : [
        { title : "Delete Account",       listHeader: "Danger Zone",                listType: "delete",         id : 5,       parentId : null }
      ]
      # kites :
      #   title : "Kites"
      #   items : [
      #     { title : "My Kites",             listHeader: "Your own Kites",             listType: "myKiteList",     id : 10,      parentId : null }
      #     { title : "All Kites",            listHeader: "Your 3rd Party Kites",       listType: "kiteList",       id : 20,      parentId : null }
      #   ]

  constructor:(options={}, data)->

    options.view = new KDView cssClass : "content-page"

    super options, data

    @itemsOrdered = []

  loadView:(mainView)->

    # SET UP VIEWS
    @navController = new AccountSideBarController
      domId : "account-nav"
    navView = @navController.getView()

    @wrapperController = new AccountContentWrapperController
      view    : wrapperView = new KDView
        domId : "account-content-wrapper"

    #ADD CONTENT SECTIONS
    @navController.sectionControllers = []
    @wrapperController.sectionLists = []
    for own sectionKey, section of items
      do =>
        @navController.sectionControllers.push lc = new AccountNavigationController
          wrapper     : no
          scrollView  : no
          viewOptions :
            type      : sectionKey
            cssClass  : "settings-menu"
          itemClass   : AccountNavigationLink
        , section

        navView.addSubView lc.getView()
        navView.addSubView new KDCustomHTMLView tagName : "hr"

        lc.getView().on 'ItemWasAdded', (view, index)=>
          view.on "click", =>
            @wrapperController.scrollTo @indexOfItem view.getData()

      for own itemKey,item of section.items
        @itemsOrdered.push item
        section.id = sectionKey
        wrapperView.addSubView wrapper = new AccountListWrapper
          cssClass : "settings-list-wrapper #{__utils.slugify(item.title)}"
        ,{item,section}
        @wrapperController.sectionLists.push wrapper

    navView.setPartial """
      <div class="kdview kdlistview">
      <h3>Legal</h3>
      <div class="kdview kdlistitemview newpage"><a href="/tos.html" target="_blank">Terms of service <span class="icon new-page"></span></a></div>
      <div class="kdview kdlistitemview newpage"><a href="/privacy.html" target="_blank">Privacy policy <span class="icon new-page"></span></a></div>
      </div>
      """

    # # SET UP SPLIT VIEW AND TOGGLERS
    # mainView.addSubView @split = split = new SplitView
    #   domId     : "account-split-view"
    #   sizes     : [188, null]
    #   views     : [navView, wrapperView]
    #   minimums  : [null, null]
    #   resizable : yes

    mainView.addSubView navView
    mainView.addSubView wrapperView

    # panel1.on "scroll", (event)=> @contentScrolled panel1, event

    # panel0.addSubView @leftToggler = new KDView
    #   cssClass : "account-sidebar-toggler left"
    #   click    : => @toggleSidebar show:no

    # split.addSubView @rightToggler = new KDView
    #   cssClass : "account-sidebar-toggler right hidden"
    #   click    : => @toggleSidebar show:yes

    @_windowDidResize()
    KD.getSingleton("windowController").registerWindowResizeListener @

    # @utils.wait => @split._windowDidResize()

  contentScrolled:(pubInst,event)->
    @__lastScrollTop or= 0
    newScrollTop = pubInst.$().scrollTop()
    return if @__lastScrollTop is newScrollTop

    topIndex = @wrapperController.getSectionIndexForScrollOffset newScrollTop
    @navController.setActiveNavItem topIndex

    @__lastScrollTop = newScrollTop

  _windowDidResize:->
    lastWrapper = @wrapperController.sectionLists[@wrapperController.sectionLists.length-1]
    lastWrapper.setHeight @navController.getView().getHeight()

  fetchProviders:->

  showReferrerModal:->
    new ReferrerModal

  # toggleSidebar:(options)->
  #   {show} = options
  #   controller = @

  #   split = @split
  #   if show
  #     split.showPanel 0, ->
  #       controller.rightToggler.hide()
  #       controller.leftToggler.show()
  #   else
  #     split.hidePanel 0, ->
  #       controller.rightToggler.show()
  #       controller.leftToggler.hide()

  indexOfItem:(item)->
    @itemsOrdered.indexOf item

  displayConfirmEmailModal:(name, username, callback=noop)->
    name or= KD.whoami().profile.firstName
    message =
      """
      Dear #{name},

      Thanks for joining Koding.<br/><br/>

      For security reasons, we need to make sure you have activated your account. When you registered, we have sent you a link to confirm your email address, please use that link to be able to continue using Koding.<br/><br/>

      If you didn't receive the email, please click to Resend email button below.<br/><br/>
      """

    modal = new KDModalView
      title            : "Please confirm your email to continue…"
      width            : 500
      overlay          : yes
      cssClass         : "new-kdmodal"
      content          : "<div class='modalformline'>#{Encoder.htmlDecode message}</div>"
      buttons          :
        "Resend email"  :
          style        : "modal-clean-red"
          callback     : => @resendHandler modal, username
        Dismiss        :
          style        : "modal-cancel"
          callback     : => modal.destroy()

    callback modal

  resendHandler : (modal, username)->

    KD.remote.api.JEmailConfirmation.resetToken username, (err)=>
      modal.buttons["Resend email"].hideLoader()
      return KD.showError err if err
      new KDNotificationView
        title     : "Check your email"
        content   : "We've sent you a confirmation mail."
        duration  : 4500
