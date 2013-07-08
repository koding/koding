class GroupPaymentHistoryModal extends KDModalViewWithForms

  constructor:(options, data)->
    {group} = options

    options =
      title                   : "Payment History"
      content                 : ''
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      cssClass                : "billing-history-modal"
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          history             :
            fields            :
              Instances       :
                type          : 'hidden'
                cssClass      : 'database-list'
            buttons           :
              Refresh         :
                style         : "modal-clean-gray"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms.history
                  @dbController.loadItems =>
                    form.buttons.Refresh.hideLoader()

    super options, data

    @dbController = new GroupPaymentHistoryListController
      group     : group
      itemClass : AccountPaymentHistoryListItem

    dbList = @dbController.getListView()

    dbListForm = @modalTabs.forms.history
    dbListForm.fields.Instances.addSubView @dbController.getView()

    @dbController.loadItems()

class GroupPaymentHistoryListController extends KDListViewController

  constructor:(options = {}, data)->
    @group = options.group
    super

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    transactions = []
    @group.getTransactions (err, trans) =>
      if err
        @instantiateListItems []
        @hideLazyLoader()
      unless err
        for t in trans
          if t.amount + t.tax is 0
            continue
          transactions.push
            status     : t.status
            amount     : ((t.amount + t.tax) / 100).toFixed(2)
            currency   : 'USD'
            createdAt  : t.datetime
            paidVia    : t.card or ""
            owner      : t.owner
            refundable : t.refundable
        if transactions.length is 0
          @addCustomItem "There are no transactions."
        else
          @instantiateListItems transactions
        @hideLazyLoader()
        callback?()

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message