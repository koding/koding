_ = require 'lodash'
kd = require 'kd'
JView = require '../../core/jview'
MainHeaderView = require '../../core/mainheaderview'
StripePaymentTabForm = require '../forms/stripepaymenttabform'
utils = require '../../core/utils'

module.exports = class StripePaymentTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    name = @getOption 'name'

    teamData = utils.getTeamData()
    @alreadyMember = teamData.signup?.alreadyMember

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new StripePaymentTabForm
      callback: @bound 'onSubmit'

    loadStripe()


  onSubmit: (formData) ->

    loadStripe().then (Stripe) =>

      { number, cvc, exp_month, exp_year } = formData

      Stripe.card.createToken {
        number    : number
        cvc       : cvc
        exp_month : exp_month
        exp_year  : exp_year
      }, (status, response) =>

        if response.error
        then @onSubmitError response.error
        else @onSubmitSuccess response


  onSubmitError: (error) ->

    @form.emit 'FormSubmitFailed'

    if input = @form[error.param]?.input
      input.parent.setClass 'validation-error'

    new kd.NotificationView { title: error.message }


  onSubmitSuccess: ({ id: stripeToken }) ->

    utils.storeNewTeamData 'payment', { stripeToken }
    kd.singletons.router.handleRoute '/Team/Username'


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Payment Info</h4>
      {{> @form}}
    </div>
    '''

track = (action, properties = {}) ->

  properties.category = 'TeamSignup'
  properties.label    = 'PaymentTab'
  utils.analytics.track action, properties


loadStripe = -> new Promise (resolve, reject) ->

  return resolve global.Stripe  if global.Stripe

  global.document.head.appendChild (new kd.CustomHTMLView
    tagName    : 'script'
    attributes :
      type     : 'text/javascript'
      src      : 'https://js.stripe.com/v2/'
    bind       : 'load'
    load       : ->
      Stripe.setPublishableKey kd.config.stripe.token
      return resolve(global.Stripe)
  ).getElement()
