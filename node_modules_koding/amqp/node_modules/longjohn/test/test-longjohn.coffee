longjohn = require '../lib/longjohn'
assert = require 'assert'

describe 'longjohn', ->
  it 'should work with normal throw', ->
    assert.throws -> throw new Error('foo')
  
  it 'should work with errors from other modules', (done) ->
    fs = require('fs')
    
    fs.readFile 'not_there.txt', 'utf8', (err, text) ->
      return done() if err? and err instanceof Error and err.stack is "Error: ENOENT, open 'not_there.txt'"
      assert.fail()
  
  it 'should track frames across setTimeout', (done) ->
    setTimeout ->
      assert.equal(new Error('foobar').stack.split(longjohn.empty_frame).length, 2)
      done()
    , 1
  
  it 'should work for issue #10', (done) ->
    a = -> b()
    b = ->
      assert.equal(new Error('this is uncaught!').stack.split(longjohn.empty_frame).length, 2);
      done()

    setTimeout(a, 0)
  
  it 'should work for issue #10-2', (done) ->
    a = -> setTimeout(b, 0)
    b = ->
      assert.equal(new Error('this is uncaught!').stack.split(longjohn.empty_frame).length, 3)
      done()
    
    setTimeout(a, 0)
  
  it 'should allow stack size limiting', (done) ->
    longjohn.async_trace_limit = 2

    counter = 0
    foo = ->
      if ++counter > 3
        assert.equal(new Error('foo').stack.split(longjohn.empty_frame).length, 2)
        return done()
      setTimeout(foo, 1)

    foo()
  
  it 'should work with on/emit', ->
    {EventEmitter} = require 'events'
    
    count = 0
    foo = -> ++count
    
    emitter = new EventEmitter()
    
    emitter.on('foo', foo)
    emitter.on('foo', foo)
    emitter.on('foo', foo)
    
    emitter.emit('foo')
    
    assert.equal(count, 3)
  
  it 'should work with removeListener', ->
    {EventEmitter} = require 'events'
    
    count = 0
    foo = -> ++count
    
    emitter = new EventEmitter()
    
    emitter.on('foo', foo)
    emitter.on('foo', foo)
    
    emitter.removeListener('foo', foo)
    
    emitter.emit('foo')
    
    assert.equal(count, 1)
  
  it 'should work with setTimeout', (done) ->
    setTimeout ->
      assert.deepEqual(Array::slice.call(arguments), [1, 2, 3])
      done()
    , 1, 1, 2, 3
  
  it 'should work with setInterval', (done) ->
    interval_id = setInterval ->
      assert.deepEqual(Array::slice.call(arguments), [1, 2, 3])
      clearInterval(interval_id)
      done()
    , 1, 1, 2, 3

  if setImmediate?
    it 'should work with setImmediate', (done) ->
      immediate_id = setImmediate ->
        assert.deepEqual(Array::slice.call(arguments), [1, 2, 3])
        clearImmediate(immediate_id)
        done()
      , 1, 2, 3
