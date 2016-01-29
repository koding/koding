JView           = require './../../core/jview'
MainHeaderView  = require './../../core/mainheaderview'
TeamPaymentForm = require './../forms/teampaymenttabform'

module.exports = class TeamPaymentTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data) ->

    super options, data

    name = @getOption 'name'

    teamData = KD.utils.getTeamData()

    @hasPaymentMethodView = new KDCustomHTMLView
      cssClass: 'payment-method-entry-form has-payment-method-wrapper'

    @hasPaymentMethodView.addSubView @hasPaymentLabel = new KDCustomHTMLView
      tagName: 'div'
      cssClass: 'has-payment-method-label'

    @hasPaymentMethodView.addSubView new KDCustomHTMLView
      tagName: 'a'
      cssClass: 'use-different-card-link'
      partial: '<div class="use-different-card-label">Use different card</div>'
      attributes: href: '#'
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
            @showError response.error or 'There is something wrong, try again.'
            return

          @switchViews {state: 'has-payment-method'}
          track 'payment method success'

          KD.utils.storeNewTeamData name,
            token: response.id
            last4: response.card.last4

          KD.singletons.router.handleRoute '/Team/Username'


    team = KD.utils.getTeamData()

    @button = new KDButtonView
      title: 'NEXT'
      style: 'TeamsModal-button TeamsModal-button--green'
      attributes: testpath: 'payment-button'
      loader: off
      callback: @bound 'submit'

    @backLink = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'TeamsModal-button-link back'
      partial      : "<i></i> <a href=\"/Team/Domain\">Back</a>"


    @on 'viewAppended', =>

      if teamData.payment?.token?
      then @switchViews {state: 'has-payment-method'}
      else @cleanupPaymentTeamData()

    @loadStripe()


  submit: ->

    if KD.utils.getTeamData().payment?.token?
      KD.singletons.router.handleRoute '/Team/Username'
    else
      @form.submit()



  loadStripe: ->

    return  if global.Stripe

    KD.utils.defer =>
      @form.toggleInputs off
      loadScript 'https://js.stripe.com/v2/', =>
        Stripe.setPublishableKey KD.config.stripe.token
        @form.toggleInputs on


  showError: (error) ->

    track 'payment method error'
    new KDNotificationView { title : error }


  cleanupPaymentTeamData: ->

    KD.utils.storeNewTeamData 'payment', null
    @switchViews {state: 'form'}


  switchViews: (options) ->

    switch options.state
      when 'form'
        @$().find('.has-payment-method-wrapper').toggleClass 'hidden', on
        @form.unsetClass 'hidden'
      when 'has-payment-method'
        @form.setClass 'hidden'
        wrapper = @$().find '.has-payment-method-wrapper'
        wrapper.toggleClass 'hidden', off

        {payment: {last4}} = KD.utils.getTeamData()
        @hasPaymentLabel.updatePartial "<span>We have **** **** **** #{last4} on file.</span>"


  pistachio: ->

    """
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
    """


track = (action) ->

  category = 'TeamSignup'
  label    = 'PaymentTab'

  KD.utils.analytics.track action, { category, label }


loadScript = (url, callback) ->

  global.document.head.appendChild (new KDCustomHTMLView
    tagName    : 'script'
    attributes :
      type     : 'text/javascript'
      src      : url
    bind       : 'load'
    load       : callback
  ).getElement()


