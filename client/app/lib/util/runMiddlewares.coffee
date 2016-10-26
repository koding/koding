{ isFunction } = require 'lodash'
async = require 'async'

# This module will check for a `middlewares` array on constructor of given
# instance.
runMiddlewaresAsync = (instance, methodName, options, callback) ->


  middlewares = getMiddlewares instance

  filterer = hasMethod methodName
  mapper = wrapAsync instance, methodName

  queue = middlewares.filter(filterer).map(mapper)
  queue = [async.constant options].concat queue

  async.waterfall queue, callback


runMiddlewaresSync = (instance, methodName, options) ->

  middlewares = getMiddlewares instance

  filterer = hasMethod methodName
  mapper = wrapSync instance, methodName

  queue = middlewares.filter(filterer).map(mapper)

  queue.reduce (opts, fn) ->
    fn opts
  , options


getMiddlewares = (instance) ->

  middlewares = \
    # first check to see if instance itself has defined middlewares array.
    instance.getMiddlewares?() or \
    # then check to see if its class has defined middlewares array.
    instance.constructor?.getMiddlewares?() or \
    # default it to an empty array.
    []

  return middlewares


hasMethod = (methodName) -> (middleware) -> isFunction(middleware[methodName])


# decorator function that accepts an instance and `methodName`. (wrap)
# (wrap) will return another function which will accept a middleware. (wrapped)
# (wrapped) is a function that which will be used with `async.middleware`
wrapAsync = (instance, methodName) -> (middleware) -> (args..., callback) ->
  method = middleware[methodName]

  async.ensureAsync(method).call instance, args..., callback


wrapSync = (instance, methodName) -> (middleware) -> (args...) ->
  method = middleware[methodName]
  return method.call(instance, args...)


module.exports = runMiddlewaresAsync
module.exports.async = runMiddlewaresAsync
module.exports.sync = runMiddlewaresSync
