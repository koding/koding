class AccountNavigationItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName    = 'a'
    options.attributes = href : "/Account/#{KD.utils.slugify data.title}"

    super options, data

    @name = @getData().title

  partial:(data)-> data.title


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

    ListView   = if listClasses[type] then listClasses[type] else KDListView
    Controller = if listClasses["#{type}Controller"] then listClasses["#{type}Controller"]

    view = new ListView cssClass : type, delegate: this

    if controller
      controller = new Controller {view}
      view       = controller.getView()

    @addSubView view

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
