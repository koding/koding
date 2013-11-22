class AccountSubscriptionsListController extends AccountListViewController

  constructor:(options={}, data)->
    options.noItemFoundText or= 'You have no subscriptions.'

    super options, data

    @getListView().on 'Reload', @bound 'loadItems'
    @loadItems()

    list = @getListView()

    list.on 'ItemWasAdded', (item) =>
      subscription = item.getData()

      item.on 'UnsubscribeRequested', =>
        @confirm 'cancel', subscription

      item.on 'ReactivateRequested', =>
        @confirm 'resume', subscription

      item.on 'PlanChangeRequested', -> debugger

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
        callback  : callback ? => subscription[action] =>
          modal.destroy()
          @loadItems()

  loadItems:->
    @removeAllItems()
    @showLazyLoader no

    paymentController = KD.getSingleton 'paymentController'

#    KD.remote.api.JPaymentSubscription.fetchUserSubscriptionsWithPlan (err, subs=[])=>
    KD.whoami().fetchPlansAndSubscriptions (err, plansAndSubscriptions) =>
      warn err  if err
      
      { subscriptions } = paymentController.groupPlansBySubscription plansAndSubscriptions
      
      subscriptions = subscriptions.filter (s) -> s.expired isnt 'expired'
      
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

    listView = @getDelegate()

    @subscription = new SubscriptionView {}, @getData()

    @controls = new SubscriptionControls {}, @getData()

    @forwardEvents @controls, [
      'PlanChangeRequested'
      'UnsubscribeRequested'
      'ReactivateRequested'
    ]

  viewAppended: JView::viewAppended

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
      when 'active'
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
