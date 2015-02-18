kd = require 'kd'
KDTabView = kd.TabView
remote = require('app/remote').getInstance()


module.exports = class EmbedCodeView extends KDTabView
  constructor: (options = {}, data) ->

    { @planCode } = options

    options.cssClass ?= "hidden product-embed"
    options.hideHandleCloseIcons ?= yes
    options.paneData ?= [

        name    : "Check Subscription"
        partial : "<pre>#{ @getCodeCheckSnippet() }</pre>"
      ,
        name    : "Get Subscribers"
        partial : "<pre>#{ @getCodeGetSnippet() }</pre>"
      ,
        name    : "Subscribe Widget"
        partial : "<pre>#{ @getCodeWidgetSnippet() }</pre>"
    ]

    super options, data

  getCodeWidgetSnippet: ->
    """
    @content = new KDButtonView
      cssClass   : "clean-gray test-input"
      title      : "Subscribed! View Video"
      callback   : ->
        console.log "Open video..."

    @payment = new PaymentWidget
      planCode        : '#{ @planCode }'
      contentCssClass : 'solid green medium'
      content         : @content

    @payment.on "subscribed", ->
      console.log "User is subscribed."
    """

  getCodeGetSnippet: ->
    """
    remote.api.JPaymentPlan.fetchPlanByCode '#{ @planCode }', (err, plan)->
      if not err and plan
        plan.fetchSubscriptions (err, subs)->
          console.log "Subscribers:", subs
    """

  getCodeCheckSnippet: ->
    """
    remote.api.JPaymentSubscription.checkUserSubscription '#{ @planCode }', (err, subscriptions)->
      if not err and subscriptions.length > 0
        console.log "User is subscribed to the plan."
    """


