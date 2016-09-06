kd      = require 'kd'
expect  = require 'expect'

AccountBilling       = require 'account/views/accountbilling'
KodingListController = require 'app/kodinglist/kodinglistcontroller'


describe 'AccountBilling', ->

  afterEach ->

    expect.restoreSpies()


  describe 'constructor', ->

    it 'should check values of initialState', ->

      view = new AccountBilling

      { subscription, paymentMethod, paymentHistory } = view.initialState

      expect(subscription).toBe   null
      expect(paymentMethod).toBe  null
      expect(paymentHistory).toBe null

    it 'should create state from initialState and options.state', ->

      view = new AccountBilling { state : { testMode : yes, subscription : 'free' } }

      { testMode, subscription } = view.state

      expect(testMode).toBeTruthy()
      expect(subscription).toEqual 'free'

    it 'should use account app storage', ->

      view = new AccountBilling

      expect(view.accountStorage).toExist()
      expect(view.accountStorage._applicationID).toEqual 'Account'
      expect(view.accountStorage._applicationVersion).toEqual '1.0'


  describe '::initViews', ->

    it 'should call initSubscription and initPaymentHistory', ->

      expect.spyOn AccountBilling.prototype, 'initSubscription'
      expect.spyOn AccountBilling.prototype, 'initPaymentHistory'

      view = new AccountBilling

      expect(view.initSubscription).toHaveBeenCalled()
      expect(view.initPaymentHistory).toHaveBeenCalled()

    it 'should create wrappers', ->

      view = new AccountBilling

      expect(view.subscriptionWrapper.hasClass('subscription-wrapper')).toBeTruthy()
      expect(view.paymentMethodWrapper.hasClass('payment-method-wrapper')).toBeTruthy()
      expect(view.paymentHistoryWrapper.hasClass('payment-history-wrapper')).toBeTruthy()


  describe '::initSubscription', ->

    it 'should call paymentController.subscriptions', ->

      { paymentController } = kd.singletons

      spy   = expect.spyOn paymentController, 'subscriptions'
      view  = new AccountBilling

      expect(spy).toHaveBeenCalled()


  describe '::initPaymentHistory', ->

    it 'should call paymentController.invoices', ->

      { paymentController } = kd.singletons

      spy   = expect.spyOn paymentController, 'invoices'
      view  = new AccountBilling

      expect(spy).toHaveBeenCalled()

    it 'should use KodingListController', ->

      { paymentController } = kd.singletons

      expect.spyOn(paymentController, 'invoices').andCall (callback) ->
        callback null, [ { name : 'kodinguser' }, { name : 'kodinguser2' } ]

      view          = new AccountBilling
      instanceCheck = view.listController instanceof KodingListController

      expect(instanceCheck).toBeTruthy()
      expect(view.listController.getOption('noItemFoundText')).toEqual 'You have no payment history'
