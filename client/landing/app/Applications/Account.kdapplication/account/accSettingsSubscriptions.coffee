class AccountSubscriptionsListController extends KDListViewController
  constructor:(options,data)->
    super options,data

    @loadItems()

    @on "reload", (data)=>
      @loadItems()

    @list = @getListView()
    @list.on 'reload', (data)=>
      @loadItems()

  loadItems: ()->
    @removeAllItems()
    @showLazyLoader no

    KD.remote.api.JRecurlySubscription.getUserSubscriptions (err, subs) =>
      if err or subs.length is 0
        @instantiateListItems []
        @hideLazyLoader()
      else
        stack = []

        subs.forEach (sub)=>
          if sub.status != 'expired'
            stack.push (cb)->
              KD.remote.api.JRecurlyPlan.getPlanWithCode sub.planCode, (err, plan)->
                return cb err  if err
                sub.plan = plan
                cb null, sub

          async.parallel stack, (err, result)=>
            if err
              result = []
            @instantiateListItems result
            @hideLazyLoader()

  loadView:->
    super
    @getView().parent.addSubView reloadButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "refresh"
      callback  : =>
        @getListView().emit "reload"

class AccountSubscriptionsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountSubscriptionsListItem
    ,options
    super options,data

class AccountSubscriptionsListItem extends KDListItemView
  constructor:(options,data)->
    options.tagName = "li"
    super options, data

    listView = @getDelegate()

    if data.status == 'canceled'
      title = 'Renew Next Month'
    else if data.status in ['active', 'modified']
      title = "Don't Renew Next Month"

    @changePlan = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : 'delete'
      tooltip     :
        title     : title
        placement : "left"
      loader      :
        color     : "#666"
        diameter  : 16
      callback    : =>
        if data.status in ['active', 'modified', 'canceled']
          editPlan listView, data
          @changePlan.hideLoader()

    if data.status == 'single'
      @changePlan.hide()


  warnUser: (message, cb)->
    modal = new KDModalView
      title        : "Warning"
      content      : "<div class='modalformline'>#{message}</div>"
      height       : "auto"
      overlay      : yes
      buttons      :
        Continue   :
          loader   :
            color  : "#ffffff"
            diameter : 16
          style    : "modal-clean-gray"
          callback : ->
            modal.destroy()
            cb?()

  editPlan: (listView, data)->
    if data.status == 'canceled'
      warnUser 'Are you sure you want to resume your subscription?', ->
        data.resume (err, res)->
          unless err
            listView.emit "reload"
    else
      warnUser 'Are you sure you want to cancel your subscription?', ->
        data.cancel (err, res)->
          unless err
            listView.emit "reload"

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    # TODO:
    # - Make UI beautiful
    # - Show monthly fee if type is recurring
    # - Hide expire date if status is not canceled
    # - Hide renew date if status is canceled

    {quantity,plan,status,renew,expires} = @getData()

    statusNotice = ""
    if status in ['active', 'modified']
      statusNotice = "Subscription for #{quantity} VM(s) is active"
    else if status == 'canceled'
      statusNotice = "Subscription for #{quantity} VM(s) will end soon"

    dateNotice = ""
    if plan.type != 'single'
      if status == 'active'
        dateNotice = "Plan will renew on #{renew}"
      else if status == 'canceled'
        dateNotice = "Plan will be available till #{expires}"

    amount = (plan.feeMonthly / 100).toFixed 2

    """
    <span class='payment-type'>#{statusNotice}</span>
    <div class='payment-details'>
      {{> @changePlan}}
      <h4>{{#(plan.title)}} - $#{amount}</h4>
      <br/>
      #{dateNotice}
    </div>
    """