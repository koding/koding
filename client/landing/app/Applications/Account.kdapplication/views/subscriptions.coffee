class AccountSubscriptionsListController extends AccountListViewController

  constructor:(options={}, data)->
    options.noItemFoundText or= 'You have no subscriptions.'

    super options, data

    @getListView().on 'Reload', @bound 'loadItems'
    @loadItems()

  loadItems:->
    @removeAllItems()
    @showLazyLoader no

    KD.remote.api.JPaymentSubscription.fetchUserSubscriptionsWithPlan (err, subs=[])=>
      warn err  if err
      subscriptions = (sub  for sub in subs when sub.expired isnt 'expired')
      @instantiateListItems subscriptions
      @hideLazyLoader()

  loadView:->
    super

    @getView().parent.addSubView reloadButton = new KDButtonView
      style     : 'clean-gray account-header-button'
      title     : ''
      icon      : yes
      iconOnly  : yes
      iconClass : 'refresh'
      callback  : @getListView().emit.bind @getListView(), 'Reload'


class AccountSubscriptionsList extends KDListView

  constructor:(options={}, data)->
    options.tagName   or= 'ul'
    options.itemClass or= AccountSubscriptionsListItem

    super options, data


class AccountSubscriptionsListItem extends KDListItemView

  constructor:(options={}, data)->
    options.tagName or= 'li'

    super options, data

    # listView = @getDelegate()
    # if data.status is 'canceled'
    #   title     = 'Renew Next Month'
    #   iconClass = 'canceled'
    # else if data.status in ['active', 'modified']
    #   title     = "Don't Renew Next Month"
    #   iconClass = 'active'

    @changePlan = new KDButtonView
    #   style       : 'clean-gray'
    #   cssClass    : 'edit-plan'
    #   icon        : yes
    #   iconOnly    : yes
    #   iconClass   : iconClass
    #   tooltip     :
    #     title     : title
    #     placement : 'left'
    #   loader      :
    #     color     : '#666'
    #     diameter  : 16
    #   callback    : =>
    #     if data.status in ['active', 'modified', 'canceled']
    #       @editPlan listView, data
    #       @changePlan.hideLoader()

  confirmOperation: (message, cb)->
    modal = new KDModalView
      title        : 'Warning'
      content      : "<div class='modalformline'>#{message}</div>"
      height       : 'auto'
      overlay      : yes
      buttons      :
        Continue   :
          loader   :
            color  : '#ffffff'
            diameter : 16
          style    : 'modal-clean-gray'
          callback : ->
            modal.destroy()
            cb?()

  editPlan: (listView, data)->
    cb = (err)-> listView.emit 'Reload'  unless err

    if data.status is 'canceled'
      @confirmOperation 'Are you sure you want to resume your subscription?', ->
        data.resume cb
    else
      @confirmOperation 'Are you sure you want to cancel your subscription?', ->
        data.cancel cb

  viewAppended: JView::viewAppended

  pistachio:->
    {quantity,plan,status,renew,expires,amount} = @getData()

    statusNotice = ''
    if status in ['active', 'modified']
      statusNotice = "Subscription for #{quantity} product(s) is active"
    else if status is 'canceled'
      statusNotice = "Subscription for #{quantity} product(s) will end soon"

    dateNotice = ''
    if plan.type isnt 'single'
      if status is 'active'
        dateNotice = "Plan will renew on #{dateFormat renew}"
      else if status is 'canceled'
        dateNotice = "Plan will be available till #{dateFormat expires}"

    amount = (amount / 100).toFixed 2

    """
    <div class='payment-details'>
      <h4>{{#(plan.title)}} - $#{amount}</h4>
      <span class='payment-type'>#{statusNotice}</span>
      {{> @changePlan}}
      <br/>
      <p>#{dateNotice}</p>
    </div>
    """
