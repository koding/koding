{ Component: ReactComponent } = require 'react'
reactMixin                    = require 'react-mixin'

module.exports = class KDReactComponent extends ReactComponent

  @include = (mixins) ->

    mixins.forEach (mixin) => reactMixin.onClass this, mixin


  ###*
   * Bind instance context to instance method with given method name. It binds
   * the correct this and then caches it for reuse later.
   *
   * @param {string} methodName
   * @return {function}
  ###
  bound: (methodName) ->

    unless typeof this[methodName] is 'function'
      throw new Error "bound: unknown method! #{methodName}"

    boundedName = "__bound__#{methodName}"

    return this[boundedName]  if this[boundedName]

    Object.defineProperty this, boundedName, { value: this[methodName].bind this }

    return this[boundedName]


  ###*
   * Bind instance context to instance method with given method name and given arguments
  ###
  lazyBound: (methodName, args...) -> this[methodName].bind this, args...
