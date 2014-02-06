class AccountSubscriptionsListController extends AccountListViewController

  constructor:(options={}, data)->
    options.noItemFoundText or= 'You have no subscriptions.'

    super options, data

    @loadItems()

    @getListView().on 'ItemWasAdded', (item) =>
      subscription = item.getData()

      item
        .on 'UnsubscribeRequested', =>
          @confirm 'cancel', subscription

        .on 'ReactivateRequested', =>
          @confirm 'resume', subscription

        .on 'PlanChangeRequested', ->
          payment = KD.getSingleton 'paymentController'

          workflow = payment.createUpgradeWorkflow tag: 'vm'

          modal = new KDModalView
            view    : workflow
            overlay : yes

          workflow.on 'Finished', modal.bound 'destroy'

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

class AccountSubscriptionsList extends KDListView

  constructor:(options={}, data)->
    options.tagName   or= 'ul'
    options.itemClass or= AccountSubscriptionsListItem

    super options, data

class AccountSubscriptionsListItem extends KDListItemView

  constructor:(options={}, data)->
    options.tagName or= 'li'
    options.type    or= 'subscription'

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

  pistachio:->
    """
      {{> @subscription}}
      {{> @controls}}
    """

class SubscriptionControls extends JView

  getStatusInfo: (subscription = @getData()) ->
    switch subscription.status
      when 'active', 'future'
        cssClass    : 'red'
        text        : 'unsubscribe'
        event       : 'UnsubscribeRequested'
        showChange  : yes
      when 'canceled', 'expired'
        cssClass    : 'yellow'
        text        : 'reactivate'
        event       : 'ReactivateRequested'
        showChange  : no

  viewAppended: ->
    @unsetClass 'kdview'
    @setClass 'controls'

    { text, cssClass, event, showChange } = @getStatusInfo()

    @statusLink = new CustomLinkView
      cssClass  : cssClass
      title     : text
      click     : (e) =>
        e.preventDefault()
        @emit event
    @addSubView @statusLink

    if showChange
      @changeLink = new CustomLinkView
        cssClass  : 'green'
        title     : 'change plan'
        click     : (e) =>
          e.preventDefault()
          @emit 'PlanChangeRequested'
      @addSubView @changeLink
