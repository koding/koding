{ assign } = require 'lodash'
expect = require 'expect'
runMiddlewares = require './runMiddlewares'

describe 'middleware utils', ->

  Bar =
    create: (options, callback) ->
      callback null, assign {}, options, { bar: this }

  Baz =
    create: (options, callback) ->
      callback null, assign {}, options, { baz: this }


  SyncBar =
    create: (options) -> assign {}, options, { bar: this }

  SyncBaz =
    create: (options) -> assign {}, options, { baz: this }


  describe 'runMiddlewares', ->

    it 'works with constructor', (done) ->
      class Foo
        @getMiddlewares = -> [Bar, Baz]
        create: (options, callback) ->
          callback null, assign {}, options, { finished: this }


      instance = new Foo

      runMiddlewares instance, 'create', { foo: instance }, (err, result) ->
        expect(result.foo).toBe instance, 'foo should be original instance'
        expect(result.bar).toBe instance, 'bar should be original instance'
        expect(result.baz).toBe instance, 'baz should be original instance'
        expect(result.finished).toNotExist()

        instance.create result, (err, result) ->
          expect(result.finished).toBe instance, 'finished should be original'
          done()


    it 'works with regular object', (done) ->

      instance =
        getMiddlewares: -> [Bar, Baz]
        create: (options, callback) ->
          callback null, assign {}, options, { finished: this }

      runMiddlewares instance, 'create', { foo: instance }, (err, result) ->
        expect(result.foo).toBe instance, 'foo should be original instance'
        expect(result.bar).toBe instance, 'bar should be original instance'
        expect(result.baz).toBe instance, 'baz should be original instance'
        expect(result.finished).toNotExist()

        instance.create result, (err, result) ->
          expect(result.finished).toBe instance, 'finished should be original'
          done()



  describe 'runMiddlewaresSync', ->

    it 'works', ->
      class Foo
        @getMiddlewares = -> [SyncBar, SyncBaz]
        create: (options) -> assign {}, options, { finished: this }


      instance = new Foo

      result = runMiddlewares.sync instance, 'create', { foo: instance }

      expect(result.foo).toBe instance, 'foo should be original instance'
      expect(result.bar).toBe instance, 'bar should be original instance'
      expect(result.baz).toBe instance, 'baz should be original instance'
      expect(result.finished).toNotExist()

      result = instance.create result

      expect(result.finished).toBe instance, 'finished should be original'


    it 'works with regular object', ->

      instance =
        getMiddlewares: -> [SyncBar, SyncBaz]
        create: (options) -> assign {}, options, { finished: this }

      result = runMiddlewares.sync instance, 'create', { foo: instance }

      expect(result.foo).toBe instance, 'foo should be original instance'
      expect(result.bar).toBe instance, 'bar should be original instance'
      expect(result.baz).toBe instance, 'baz should be original instance'
      expect(result.finished).toNotExist()

      result = instance.create result

      expect(result.finished).toBe instance, 'finished should be original'
