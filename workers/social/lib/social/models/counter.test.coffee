# Test Model
JCounter = require './counter'

# Helpers
{ async
  expect
  generateRandomString
  checkBongoConnectivity } = require '../../../testhelper'

NAMESPACES              = []
LIMIT_EXCEEDED_ERROR    = 'Provided limit has been reached'
NAMESPACE_MISSING_ERROR = 'namespace is required'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = ->

  describe 'workers.social.counter.increment', ->

    namespace = generateRandomString()
    NAMESPACES.push namespace
    options = { namespace }

    it 'should create a counter if not exists', (done) ->

      JCounter.increment options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 1
        done()

    it 'should increment the counter', (done) ->

      JCounter.increment options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 2
        done()

    it 'should not allow to pass max value', (done) ->

      options.max = 2

      JCounter.increment options, (err, count) ->
        expect(err).to.exist
        expect(err.message).to.equal LIMIT_EXCEEDED_ERROR
        expect(count).to.not.exist
        done()

    it 'should allow to use different types', (done) ->

      options.type = 'test'

      JCounter.increment options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 1
        done()

    it 'should support increment with amount', (done) ->

      options.max    = 9
      options.amount = 5

      JCounter.increment options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 6
        done()

    it 'should not fail when wrong amount provided', (done) ->

      options.amount = -2

      JCounter.increment options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 8
        done()

    it 'should not fail when amount provided is not a number', (done) ->

      options.amount = 'foo'

      JCounter.increment options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 9
        done()

    it 'should not allow to pass max value when amount provided', (done) ->

      options.amount = 3

      JCounter.increment options, (err, count) ->
        expect(err).to.exist
        expect(err.message).to.equal LIMIT_EXCEEDED_ERROR
        expect(count).to.not.exist
        done()

    it 'should fail if namespace not provided', (done) ->

      JCounter.increment {}, (err, count) ->
        expect(err).to.exist
        expect(err.message).to.equal NAMESPACE_MISSING_ERROR
        expect(count).to.not.exist
        done()


  describe 'workers.social.counter.decrement', ->

    namespace = generateRandomString()
    NAMESPACES.push namespace
    options = { namespace }

    it 'should create a counter if not exists', (done) ->

      JCounter.decrement options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal -1
        done()

    it 'should decrease the counter', (done) ->

      JCounter.decrement options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal -2
        done()

    it 'should not allow to pass min value', (done) ->

      options.min = -2

      JCounter.decrement options, (err, count) ->
        expect(err).to.exist
        expect(err.message).to.equal LIMIT_EXCEEDED_ERROR
        expect(count).to.not.exist
        done()

    it 'should allow to use different types', (done) ->

      options.type = 'test'

      JCounter.decrement options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal -1
        done()

    it 'should support decrement with amount', (done) ->

      options.min    = -9
      options.amount = 5

      JCounter.decrement options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal -6
        done()

    it 'should not fail when wrong amount provided', (done) ->

      options.amount = 2

      JCounter.decrement options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal -8
        done()

    it 'should not fail when amount provided is not a number', (done) ->

      options.amount = 'bar'

      JCounter.decrement options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal -9
        done()

    it 'should not allow to pass min value when amount provided', (done) ->

      options.amount = -3

      JCounter.decrement options, (err, count) ->
        expect(err).to.exist
        expect(err.message).to.equal LIMIT_EXCEEDED_ERROR
        expect(count).to.not.exist
        done()

    it 'should fail if namespace not provided', (done) ->

      JCounter.decrement {}, (err, count) ->
        expect(err).to.exist
        expect(err.message).to.equal NAMESPACE_MISSING_ERROR
        expect(count).to.not.exist
        done()


  describe 'workers.social.counter.count', ->

    namespace = generateRandomString()
    NAMESPACES.push namespace
    options = { namespace }

    it 'should return 0 as count if counter not exists', (done) ->

      JCounter.count options, (err, count) ->
        expect(err).to.not.exist
        expect(count).to.equal 0
        done()

    it 'should return real count if counter exists', (done) ->

      queue = [ ]
      COUNT = 5

      for i in [1..COUNT]
        queue.push (next) ->
          JCounter.increment options, (err) ->
            expect(err).to.not.exist
            next()

      queue.push (next) ->
        JCounter.count options, (err, count) ->
          expect(err).to.not.exist
          expect(count).to.equal COUNT
          next()

      async.series queue, done


  describe 'workers.social.counter.reset', ->

    namespace = generateRandomString()
    NAMESPACES.push namespace
    options = { namespace }

    it 'should only reset the counter of given type', (done) ->

      queue = [

        (next) ->
          JCounter.increment options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            next()
        (next) ->
          options.type = generateRandomString()
          JCounter.increment options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            next()
        (next) ->
          JCounter.reset options, (err) ->
            expect(err).to.not.exist
            next()
        (next) ->
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 0
            next()
        (next) ->
          options = { namespace: options.namespace }
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            next()

      ]

      async.series queue, done


  describe 'workers.social.counter.setCount', ->

    namespace = generateRandomString()
    NAMESPACES.push namespace
    options = { namespace, value: 10 }

    it 'should set the provided count for given namespace and type', (done) ->

      queue = [

        (next) ->
          JCounter.setCount options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 10
            next()
        (next) ->
          options.type = generateRandomString()
          JCounter.setCount options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 10
            next()
        (next) ->
          JCounter.decrement options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 9
            next()
        (next) ->
          JCounter.setCount options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 10
            next()
        (next) ->
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 10
            next()

      ]

      async.series queue, done


afterTests = ->

  after (done) ->

    queue = [ ]

    NAMESPACES.forEach (namespace) -> queue.push (next) ->
      JCounter.reset { namespace }, (err) ->
        expect(err).to.not.exist
        next()

    async.series queue, done


beforeTests()

runTests()

afterTests()
