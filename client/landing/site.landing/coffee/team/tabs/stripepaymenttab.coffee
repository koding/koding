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

    utils.loadStripe()


  onSubmit: (formData) ->

    if utils.getPayment()
      return @onSubmitSuccess()

    utils.authorizeCreditCard(formData)
      .then @bound 'onSubmitSuccess'
      .catch @bound 'onSubmitError'

  onSubmitError: (error) ->

    @form.emit 'FormSubmitFailed'

    if view = @form[error.param]
      input = view.input
    else
      try
        if error.code is 'card_declined'
          input = @form['number'].input
      catch
        error = { message: 'There is a problem. Please try again!' }

    input?.parent.setClass 'validation-error'
    new kd.NotificationView { title: error.message }


  onSubmitSuccess: ->

    @form.button.hideLoader()
    utils.storeNewTeamData 'payment', {}
    kd.singletons.router.handleRoute '/Team/Username'


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Billing Information</h4>
      <h5>We <strong>never charge you</strong> without asking first.</h5>
      {{> @form}}
    </div>
    '''

track = (action, properties = {}) ->

  properties.category = 'TeamSignup'
  properties.label    = 'PaymentTab'
  utils.analytics.track action, properties


