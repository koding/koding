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
    mountsController           : AccountMountListController
    mounts                     : AccountMountList
    reposController            : AccountRepoListController
    repos                      : AccountRepoList
    keysController             : AccountSshKeyListController
    keys                       : AccountSshKeyList
    kodingKeysController       : AccountKodingKeyListController
    kodingKeys                 : AccountKodingKeyList
    delete                     : DeleteAccountView

  viewAppended:->

    {listType, listHeader} = @getData()

    @addSubView @header = new KDHeaderView type : "medium", title : listHeader
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
