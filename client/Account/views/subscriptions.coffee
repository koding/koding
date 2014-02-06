class AccountSubscriptionsListController extends AccountListViewController

  constructor:(options={}, data)->
    options.noItemFoundText or= 'You have no subscriptions.'

    super options, data

    @loadItems()

    @getListView().on 'ItemWasAdded', (item) =>
      subscription = item.getData()

      subscription.plan.fetchProducts (err, products) ->
        return  if KD.showError err

        item.setProductComponents subscription, products

      item
        .on 'UnsubscribeRequested', =>
          @confirm 'cancel', subscription

        .on 'ReactivateRequested', =>
          @confirm 'resume', subscription

        .on 'PlanChangeRequested', ->
          route =
            if "vm" in subscription.tags
            then "/Pricing/Developer"
            else if "custom-plan" in subscription.tags
            then "/Pricing/Team"
          KD.singleton("router").handleRoute route

  getConfirmationText = (action, subscription) -> switch action
    when 'cancel'
      'Are you sure you want to cancel this subscription?'
    when 'resume'
      'Are you sure you want to reactivate this subscription?'

  getConfirmationButtonText = (action, subscription) -> switch action
    when 'cancel' then 'Unsubscribe'
    when 'resume' then 'Reactivate'

  confirm: (action, subscription, callback) ->
    modal = KDModalView.confirm
      title       : 'Are you sure?'
      description : getConfirmationText action, subscription
      subView     : new SubscriptionView {}, subscription
      ok          :
        title     : getConfirmationButtonText action, subscription
        callback  : callback ? => subscription[action] (err) =>
          KD.showError err
          modal.destroy()
          @loadItems()

  loadItems:->
    @removeAllItems()
    @showLazyLoader no

    payment = KD.getSingleton 'paymentController'

    payment.once 'SubscriptionDebited', @bound 'loadItems'

    status = status: $in: [
      'active'
      'live'
      'canceled'
      'future'
      'past_due'
      'expired'
      'in_trial'
    ]

    payment.fetchSubscriptionsWithPlans status, (err, subscriptions) =>
      @instantiateListItems subscriptions.filter (subscription) ->
        subscription.status isnt 'expired'
      @hideLazyLoader()

  loadView:->
    super

    @getView().parent.addSubView reloadButton = new KDButtonView
      style     : 'solid green small account-header-button'
      title     : ''
      icon      : yes
      iconOnly  : yes
      iconClass : 'refresh'
      callback  : @bound 'loadItems'

class AccountSubscriptionsList extends KDListView

  constructor:(options={}, data)->
    options.tagName   or= 'ul'
    options.itemClass or= AccountSubscriptionsListItem

    super options, data

class AccountSubscriptionsListItem extends KDListItemView

  constructor:(options={}, data)->
    options.tagName or= 'li'

    super options, data

    listView = @getDelegate()

    subscription = @getData()

    @subscription = new SubscriptionView {}, subscription

    @controls = new SubscriptionControls {}, subscription

    @forwardEvents @controls, [
      'PlanChangeRequested'
      'UnsubscribeRequested'
      'ReactivateRequested'
    ]

  viewAppended: JView::viewAppended

  setProductComponents: (subscription, components) ->
    @addSubView new SubscriptionUsageView {
      subscription
      components
    }

  pistachio:->
    """
    <div class='payment-details'>
      {{> @subscription}}
      {{> @controls}}
    </div>
    """

class SubscriptionControls extends JView

  getStatusInfo: (subscription = @getData()) ->
    switch subscription.status
      when 'active', 'future'
        text        : 'unsubscribe'
        event       : 'UnsubscribeRequested'
        showChange  : yes
      when 'canceled', 'expired'
        text        : 'reactivate'
        event       : 'ReactivateRequested'
        showChange  : no

  viewAppended: ->
    @unsetClass 'kdview'
    @setClass 'controls'

    { text, event, showChange } = @getStatusInfo()

    if showChange
      @changeLink = new CustomLinkView
        title     : 'change plan'
        click     : (e) =>
          e.preventDefault()
          @emit 'PlanChangeRequested'
      @addSubView @changeLink
      @setPartial ' | '

    @statusLink = new CustomLinkView
      title     : text
      click     : (e) =>
        e.preventDefault()
        @emit event
    @addSubView @statusLink
