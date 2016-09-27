kd              = require 'kd'
JView           = require './../../core/jview'
MainHeaderView  = require './../../core/mainheaderview'
TeamPaymentForm = require './../forms/teampaymenttabform'
utils           = require './../../core/utils'

module.exports = class TeamPaymentTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data) ->

    super options, data

    name = @getOption 'name'

    teamData = utils.getTeamData()

    @hasPaymentMethodView = new kd.CustomHTMLView
      cssClass: 'payment-method-entry-form has-payment-method-wrapper'

    @hasPaymentMethodView.addSubView @hasPaymentLabel = new kd.CustomHTMLView
      tagName: 'div'
      cssClass: 'has-payment-method-label'

    @hasPaymentMethodView.addSubView new kd.CustomHTMLView
      tagName: 'a'
      cssClass: 'use-different-card-link'
      partial: '<div class="use-different-card-label">Do you want to use a different card?</div>'
      attributes: { href: '#' }
      click: @bound 'cleanupPaymentTeamData'


    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamPaymentForm
      callback: (formData) =>

        track 'payment method submit begin'

        { cardNumber, cardCVC, cardName
          cardMonth, cardYear
        } = formData

        # Just because stripe validates both 2 digit
        # and 4 digit year, and different types of month
        # we are enforcing those, other than length problems
        # Stripe will take care of the rest. ~U
        cardYear  = null  if cardYear.length isnt 4
        cardMonth = null  if cardMonth.length isnt 2

        Stripe.card.createToken {
          number    : cardNumber
          cvc       : cardCVC
          exp_month : cardMonth
          exp_year  : cardYear
          name      : cardName
        }, (status, response) =>

          if response.error
            @showError response.error.message or 'There is something wrong, try again.'
            return

          track 'payment method success'

          utils.storeNewTeamData name,
            token: response.id
            last4: response.card.last4

          @switchViews { state: 'has-payment-method' }
          kd.singletons.router.handleRoute '/Team/Username'



    @button = new kd.ButtonView
      title: 'NEXT'
      style: 'TeamsModal-button'
      attributes: { testpath: 'payment-button' }
      loader: off
      callback: @bound 'submit'

    @backLink = new kd.CustomHTMLView
      tagName      : 'span'
      cssClass     : 'TeamsModal-button-link back'
      partial      : '<i></i> <a href=\"/Team/Domain\">Back</a>'


    @on 'viewAppended', =>

      if teamData.payment?.token?
      then @switchViews { state: 'has-payment-method' }
      else @cleanupPaymentTeamData()

    @loadStripe()


  submit: ->

    if utils.getTeamData().payment?.token?
      kd.singletons.router.handleRoute '/Team/Username'
    else
      @form.submit()



  loadStripe: ->

    return  if global.Stripe

    kd.utils.defer =>
      @form.toggleInputs off
      loadScript 'https://js.stripe.com/v2/', =>
        Stripe.setPublishableKey kd.config.stripe.token
        @form.toggleInputs on


  showError: (error) ->

    track 'payment method error'
    new kd.NotificationView { title : error }


  cleanupPaymentTeamData: ->

    utils.storeNewTeamData 'payment', null
    @switchViews { state: 'form' }


  switchViews: (options) ->

    switch options.state
      when 'form'

        @$().find('.has-payment-method-wrapper').toggleClass 'hidden', on
        @form.unsetClass 'hidden'
      when 'has-payment-method'
        @form.setClass 'hidden'
        wrapper = @$().find '.has-payment-method-wrapper'
        wrapper.toggleClass 'hidden', off

        { payment: { last4 } } = utils.getTeamData()
        @hasPaymentLabel.updatePartial "<span>We have **** **** **** #{last4} on file.</span>"


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Payment Info</h4>
      <h5>You will not be charged during this trial period.</h5>
      {{> @hasPaymentMethodView}}
      {{> @form}}
      <div class="clearfix">
        {{> @button}}
        {{> @backLink}}
      </div>
    </div>
    '''


track = (action) ->

  category = 'TeamSignup'
  label    = 'PaymentTab'

  utils.analytics.track action, { category, label }


loadScript = (url, callback) ->

  global.document.head.appendChild (new kd.CustomHTMLView
    tagName    : 'script'
    attributes :
      type     : 'text/javascript'
      src      : url
    bind       : 'load'
    load       : callback
  ).getElement()
