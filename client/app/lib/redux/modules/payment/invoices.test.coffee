expect = require 'expect'
configureStore = require 'redux-mock-store'

fixtures = require 'app/redux/services/fixtures/payment'
{ reducer } = invoices = require './invoices'

describe 'redux/modules/invoices#reducer', ->

  it 'should return the initial state', ->

    expect(reducer(undefined, {})).toEqual
      invoices: {}
      items: {}


  it 'should handle LOAD.SUCCESS', ->

    fixtureInvoiceId = fixtures.invoices.data[0].id
    fixtureItemId = fixtures.invoices.data[0].lines.data[0].id

    state = reducer state,
      type: invoices.LOAD.SUCCESS
      result: fixtures.invoices

    expect(Object.keys(state.invoices)).toEqual [fixtureInvoiceId]
    expect(Object.keys(state.items)).toEqual [fixtureItemId]


describe 'redux/modules/invoices#actions', ->

  { Endpoints } = paymentService = require 'app/redux/services/payment'

  mockStore = configureStore [
    require('app/redux/middleware/payment')(require 'app/redux/services/payment')
    require('app/redux/middleware/promise')
  ]

  mock = store = null

  before ->
    store = mockStore({})
    mock = require('app/util/mockHttpClient')(paymentService.client)

  after -> mock.restore()

  beforeEach ->
    mock.reset()
    store.clearActions()


  describe '#load', ->

    it 'should dispatch success action', ->
      mock
        .onGet Endpoints.InvoiceList
        .reply 200, fixtures.invoices

      loadAction = invoices.load()

      store.dispatch(loadAction).then ->
        expect(store.getActions()).toEqual [
          { type: invoices.LOAD.BEGIN }
          { type: invoices.LOAD.SUCCESS, result: fixtures.invoices }
        ]

    it 'should dispatch fail action', ->
      mock.onGet(Endpoints.InvoiceList).reply 400

      loadAction = invoices.load()

      store.dispatch(loadAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe invoices.LOAD.BEGIN
        expect(actions[1].type).toBe invoices.LOAD.FAIL
