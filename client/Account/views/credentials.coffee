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
      iconOnly  : yes
      callback  : => new KDNotificationView title : "Coming soon."

class AccountCredentialList extends KDListView

  constructor:(options = {}, data)->

    options.tagName  ?= "ul"
    options.itemClass = AccountCredentialListItem

    super options, data

  deleteItem: (item)->

    credential = item.getData()

    modal = KDModalView.confirm
      title       : "Remove credential"
      description : "Do you want to remove ?"
      ok          :
        title     : "Yes"
        callback  : -> credential.delete (err)->

          modal.destroy()

          unless KD.showError err
            item.destroy()


class AccountCredentialListItem extends KDListItemView

  constructor: (options = {}, data)->
    options.cssClass = KD.utils.curry "credential-item", options.cssClass
    super options, data

    delegate = @getDelegate()

    @deleteButton = new KDButtonView
      title    : "Delete"
      cssClass : "solid small red"
      callback : => delegate.deleteItem this

  viewAppended: JView::viewAppended

  pistachio:->
    "{{#(vendor)}} - {{#(title)}} -- {{> @deleteButton}}"
