# DB Connections
{ argv }   = require 'optimist'
KONFIG     = require('koding-config-manager').load("main.#{argv.c}")
mongo      = process.env.MONGO_URL or "mongodb://#{ KONFIG.mongo }"

# Bongo
Bongo      = require 'bongo'
{ daisy }  = Bongo

# Test Model
JCounter   = require './counter'

# Helpers
{ expect } = require 'chai'
{ generateRandomString, checkBongoConnectivity } = require '../../../testhelper'

# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = ->

  LIMIT_EXCEEDED_ERROR = 'Provided limit has been reached'
  NAMESPACES           = []

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
        queue.push ->
          JCounter.increment options, (err) ->
            expect(err).to.not.exist
            queue.next()

      queue.push ->
        JCounter.count options, (err, count) ->
          expect(err).to.not.exist
          expect(count).to.equal COUNT
          done()

      queue.push -> done()

      daisy queue


  describe 'workers.social.counter.reset', ->

    namespace = generateRandomString()
    NAMESPACES.push namespace
    options = { namespace }

    it 'should only reset the counter of given type', (done) ->

      queue = [
        ->
          JCounter.increment options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            queue.next()
        ->
          options.type = generateRandomString()
          JCounter.increment options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            queue.next()
        ->
          JCounter.reset options, (err) ->
            expect(err).to.not.exist
            queue.next()
        ->
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 0
            queue.next()
        ->
          options = { namespace: options.namespace }
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            queue.next()
      ]

      queue.push -> done()

      daisy queue

    it 'should reset counters with namespaces', (done) ->

      queue = [ ]

      NAMESPACES.forEach (namespace) -> queue.push ->
        JCounter.reset { namespace }, (err) ->
          expect(err).to.not.exist
          queue.next()

      queue.push -> done()

      daisy queue


beforeTests()

runTests()
