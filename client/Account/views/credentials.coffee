class AccountCredentialListController extends AccountListViewController

  constructor:(options = {}, data)->

    options.noItemFoundText = "You have no credentials."
    super options, data

    @loadItems()

  loadItems:->

    @removeAllItems()
    @showLazyLoader()

    { JCredential } = KD.remote.api

    JCredential.some {}, { limit: 30 }, (err, credentials)=>

      @hideLazyLoader()

      return if KD.showError err, \
        KodingError : "Failed to fetch credentials, try again later."

      @instantiateListItems credentials
      log credentials

  loadView:->

    super

    view = @getView().parent

    view.addSubView addButton = new KDButtonView
      style     : "solid green small account-header-button"
      iconClass : "plus"
      callback  : => new KDNotificationView title : "Coming soon."

class AccountCredentialList extends KDListView

  constructor:(options = {}, data)->

    options.tagName  ?= "ul"
    options.itemClass = AccountCredentialListItem

    super options, data

class AccountCredentialListItem extends KDListItemView

  viewAppended: JView::viewAppended

  pistachio:->
    "{{#(vendor)}} - {{#(title)}}"