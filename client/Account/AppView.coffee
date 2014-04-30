class AccountListWrapper extends KDView

  listClasses =
    username                   : AccountEditUsername
    security                   : AccountEditSecurity
    emailNotifications         : AccountEmailNotifications
    linkedAccountsController   : AccountLinkedAccountsListController
    linkedAccounts             : AccountLinkedAccountsList
    referralSystemController   : AccountReferralSystemListController
    referralSystem             : AccountReferralSystemList
    historyController          : AccountPaymentHistoryListController
    history                    : AccountPaymentHistoryList
    methodsController          : AccountPaymentMethodsListController
    methods                    : AccountPaymentMethodsList
    subscriptionsController    : AccountSubscriptionsListController
    subscriptions              : AccountSubscriptionsList
    editorsController          : AccountEditorListController
    editors                    : AccountEditorList
    keysController             : AccountSshKeyListController
    keys                       : AccountSshKeyList
    kodingKeysController       : AccountKodingKeyListController
    kodingKeys                 : AccountKodingKeyList
    credentialsController      : AccountCredentialListController
    credentials                : AccountCredentialList
    deleteAccount              : DeleteAccountView

  viewAppended:->
    {listType} = @getData()

    type = if listType then listType or ''

    listViewClass   = if listClasses[type] then listClasses[type] else KDListView
    controllerClass = if listClasses["#{type}Controller"] then listClasses["#{type}Controller"]

    @addSubView view = new listViewClass cssClass : type, delegate: this
    if controllerClass
      controller   = new controllerClass
        view       : view
        wrapper    : no
        scrollView : no

class AccountNavigationItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName    = 'a'
    options.attributes = href : "/Account/#{data.slug}"

    super options, data

    @name = @getData().title

  partial:(data)-> data.title

class AccountsSwappable extends KDView
  constructor:(options,data)->
    options = $.extend
      views : []          # an Array of two KDView instances
    ,options
    super
    @setClass "swappable"
    @addSubView(@view1 = @options.views[0]).hide()
    @addSubView @view2 = @options.views[1]

  swapViews:->
    if @view1.$().is(":visible")
      @view1.hide()
      @view2.show()
    else
      @view1.show()
      @view2.hide()
