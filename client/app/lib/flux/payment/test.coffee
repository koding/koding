expect = require 'expect'

Reactor = require 'app/flux/base/reactor'
PaymentFlux = require './'

describe 'PaymentFlux', ->

  it 'loads stripe client', (done) ->

    reactor = new Reactor
    { actions, getters } = PaymentFlux reactor

    expect(global.Stripe).toNotExist()
    expect(getters.paymentValues().get 'isStripeClientLoaded').toBe no

    actions.loadStripeClient().then ->

      expect(global.Stripe).toExist()
      expect(getters.paymentValues().get 'isStripeClientLoaded').toBe yes

      done()


  it 'should create a stripe token', (done) ->

    reactor = new Reactor
    { actions, getters } = PaymentFlux reactor

    options =
      cardNumber : '4111111111111111'
      cardCVC    : '111'
      cardMonth  : '11'
      cardYear   : '2017'
      cardName   : 'John Doe'

    actions.createStripeToken(options).then ({ token }) ->

      expect(getters.paymentValues().get 'stripeToken').toBe token
      done()

    .catch (err) -> done err


  it 'should subscribe a group', (done) ->

    reactor = new Reactor
    {actions, getters} = PaymentFlux reactor

    options =
      cardNumber : '4111111111111111'
      cardCVC    : '111'
      cardMonth  : '11'
      cardYear   : '2017'
      cardName   : 'John Doe'

    actions.createStripeToken(options).then ({ token }) ->
      actions.subscribeGroupPlan({ token }).then ({ response }) ->

        expected = getters.paymentValues().get('groupPlan').toJS()
        expect(expected).toEqual(response)

      .catch (err) -> done err
    .catch (err) -> done err


