class AccountNavigationLink extends KDListItemView

  constructor:(options,data)->
    super
    @name = data.title

  partial:(data)->
    "<div class='navigation-item account clearfix'>
        <a class='title' href='#'><span class='main-nav-icon #{__utils.slugify data.title}'></span>#{data.title}</a>
    </div>"


class AccountListWrapper extends KDView

  listClasses =
    personal                         :
      username                       : AccountEditUsername
      security                       : AccountEditSecurity
      emailNotifications             : AccountEmailNotifications
      linkedAccountsController       : AccountLinkedAccountsListController
      linkedAccounts                 : AccountLinkedAccountsList
      referralSystemController       : AccountReferralSystemListController
      referralSystem                 : AccountReferralSystemList
    billing                          :
      historyController              : AccountPaymentHistoryListController
      history                        : AccountPaymentHistoryList
      methodsController              : AccountPaymentMethodsListController
      methods                        : AccountPaymentMethodsList
      subscriptionsController        : AccountSubscriptionsListController
      subscriptions                  : AccountSubscriptionsList
    develop                          :
      editorsController              : AccountEditorListController
      editors                        : AccountEditorList
      mountsController               : AccountMountListController
      mounts                         : AccountMountList
      reposController                : AccountRepoListController
      repos                          : AccountRepoList
      keysController                 : AccountSshKeyListController
      keys                           : AccountSshKeyList
      kodingKeysController           : AccountKodingKeyListController
      kodingKeys                     : AccountKodingKeyList
    danger                           :
      delete                         : DeleteAccountView

  viewAppended:->

    data = @getData()

    @addSubView @header = new KDHeaderView type : "medium", title : data.item.listHeader
    id    = if data.section?.id   then data.section.id    or 'default'
    type  = if data.item.listType then data.item.listType or 'view'

    ListView = if listClasses[id]?[type]
    then listClasses[id][type]
    else KDListView

    Controller = if listClasses[id]?["#{type}Controller"]
    then listClasses[id]["#{type}Controller"]
    else KDListViewController

    controller = new Controller
      view     : new ListView cssClass : "#{id}-#{type}", delegate: this

    @addSubView controller.getView()

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
