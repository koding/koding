unless 'first' of Array.prototype
  Object.defineProperty Array.prototype, 'first',
    get : -> this[0]

unless 'last' of Array.prototype
  Object.defineProperty Array.prototype, 'last',
    get : -> this[this.length-1]

module.exports = class ResponseDecorator

  constructor:(@cacheObjects, @overviewObjects)->

  decorate:->
    response =
      isFull     : null
      _id        : null
      activities : @cacheObjects
      from       : @overviewObjects.first?.createdAt?.first or 1
      to         : @overviewObjects.last?.createdAt?.first  or 2
      overview   : @overviewObjects

    return response
