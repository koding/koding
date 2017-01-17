expect = require 'expect'
configureStore = require 'redux-mock-store'

fixtures = require 'app/redux/services/fixtures/stripe'
{ reducer } = stripe = require './stripe'

describe 'redux/modules/stripe#reducer', ->

  it 'should return the initial state', ->

    expect(reducer undefined, {}).toEqual
      errors: null


  it 'should handle CREATE_TOKEN.FAIL', ->

    state = reducer undefined, {}

    state = reducer state,
      type: stripe.CREATE_TOKEN.FAIL
      error: fixtures.createTokenError.number

    expect(state.errors).toExist()
    expect(state.errors).toEqual([fixtures.createTokenError.number])


  it 'should clear errors on CREATE_TOKEN.BEGIN and CREATE_TOKEN.SUCCESS', ->

    state = reducer undefined, {}

    # add some error to state
    afterFail = reducer state,
      type: stripe.CREATE_TOKEN.FAIL
      error: fixtures.createTokenError.number

    afterBegin = reducer afterFail,
      type: stripe.CREATE_TOKEN.BEGIN

    afterSuccess = reducer afterFail,
      type: stripe.CREATE_TOKEN.SUCCESS

    expect(afterBegin.errors).toBe null
    expect(afterSuccess.errors).toBe null


describe 'redux/modules/stripe#actions', ->

  # appendHeadElement does window stuff, it fails on mocha-webpack.
  # so mock it out!
  stripeService = require('inject!app/redux/services/stripe')({
    'app/lib/appendHeadElement': ->
  })

  mockStore = configureStore [
    require('app/redux/middleware/stripe')(stripeService, 'stripe_config_key')
    require('app/redux/middleware/promise')
  ]

  store = null

  before ->
    store = mockStore {}

  beforeEach ->
    # make sure there is a client. In theory this is `global.Stripe` when
    # Stripe.js is loaded to page.
    expect.spyOn(stripeService, 'ensureClient').andReturn Promise.resolve({})
    store.clearActions()

  afterEach -> expect.restoreSpies()

  describe 'createToken', ->

    it 'should dispatch success action', ->
      expect
        .spyOn stripeService, 'createToken'
        .andReturn Promise.resolve(fixtures.createTokenSuccess)

      correctCardOptions =
        number: '4242 4242 4242 4242'
        cvc: '111'
        exp_month: '12'
        exp_year: '2020'
        email: 'foo@koding.com'

      createTokenAction = stripe.createToken correctCardOptions

      store.dispatch(createTokenAction).then ->
        expect(store.getActions()).toEqual [
          { type: stripe.CREATE_TOKEN.BEGIN }
          { type: stripe.CREATE_TOKEN.SUCCESS, result: fixtures.createTokenSuccess }
        ]


    it 'should dispatch fail action', ->

      createTokenErrors = _.values fixtures.createTokenError

      expect
        .spyOn stripeService, 'createToken'
        .andReturn Promise.reject(createTokenErrors)

      wrongCardOpts =
        number: ''
        cvc: ''
        exp_month: ''
        exp_year: ''
        email: ''

      createTokenAction = stripe.createToken wrongCardOpts

      store.dispatch(createTokenAction).then ->
        expect(store.getActions()).toEqual [
          { type: stripe.CREATE_TOKEN.BEGIN }
          { type: stripe.CREATE_TOKEN.FAIL, error: createTokenErrors }
        ]
