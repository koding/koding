_ = require 'lodash'
kd = require 'kd'

MainHeaderView = require '../../core/mainheaderview'
StripePaymentTabForm = require '../forms/stripepaymenttabform'
utils = require '../../core/utils'
StripeDeclineErrors = require '../../core/stripeerrors'

module.exports = class StripePaymentTab extends kd.TabPaneView

  constructor: (options = {}, data) ->

    super options, data

    name = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new StripePaymentTabForm
      onSubmitSuccess: @bound 'onSubmitSuccess'
      onSubmitError: @bound 'onSubmitError'
      shouldSkip: kd.config.environment isnt 'production'


  onSubmitError: (error = { message: 'There is a problem. Please try again!' }) ->

    @form.emit 'FormSubmitFailed'

    if /number/.test error?.code
      @form.number.decorateValidation error.message
    else if /cvc/.test error?.code
      @form.cvc.decorateValidation error.message
    else if /expiry/.test error?.code
      @form.expiration.decorateValidation error.message
    else if error?.decline_code and StripeDeclineErrors[error.decline_code]
      @form.showFatalError StripeDeclineErrors[error.decline_code]
    else
      @form.number.decorateValidation error.message


  onSubmitSuccess: ->

    @form.button.hideLoader()
    kd.singletons.router.handleRoute '/Team/Username'


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Billing Information</h4>
      <h5 class="bordered">We <strong>never charge you</strong> without asking first.</h5>
      {{> @form}}
    </div>
    '''

track = (action, properties = {}) ->

  properties.category = 'TeamSignup'
  properties.label    = 'PaymentTab'
  utils.analytics.track action, properties
