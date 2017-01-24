{ Module }      = require 'jraphical'
KodingError     = require '../error'


module.exports  = class JCounter extends Module

  DUPLICATE_ERR = 11000

  @set

    # WARNING! ~ GG
    # to make this working properly we need a compound index here and since
    # bongo is not supporting them we need to manually define following:
    #
    #   - { namespace: 1, type: 1 } (unique)
    #

    sharedEvents :
      static     : [ ]
      instance   : [ ]

    schema       :

      namespace  :
        type     : String
        required : yes

      type       :
        type     : String
        default  : -> 'main'

      current    :
        type     : Number
        default  : -> 0


  # Helpers
  # -------

  handle = (callback) -> (err, counter) ->
    if err
      if err.code is DUPLICATE_ERR
        callback new KodingError 'Provided limit has been reached'
      else
        callback err
    else
      { current } = counter.value
      callback null, current

  update = (options, amount, callback) ->

    { namespace, type, max, min } = options

    type ?= 'main'
    query = { namespace, type }

    if amount > 0
      if max? and typeof max is 'number'
        query.current = { $lte: max - amount }
    else
      if min? and typeof min is 'number'
        query.current = { $gte: min - amount }

    operation = { $inc: { current: amount } }
    options   = { new: yes, upsert: yes }

    JCounter.findAndModify query, null, operation, options, handle callback


  parse = (options, direction) ->

    { amount, namespace } = options

    unless namespace?
      return [ new KodingError 'namespace is required' ]

    if not amount or typeof amount isnt 'number' # even it's zero
      return [ null, direction ]

    # if amount is negative but direction is positive reverse and vice versa
    if (amount > 0 and direction is -1) or (amount < 0 and direction is 1)
      amount *= -1

    return [ null, amount ]


  # Private Methods
  # ---------------

  # Static Methods

  @increment = (options, callback) ->

    [ err, amount ] = parse options, 1
    return callback err  if err
    update options, amount, callback


  @decrement = (options, callback) ->

    [ err, amount ] = parse options, -1
    return callback err  if err
    update options, amount, callback


  @reset = (options, callback) ->

    { namespace, type } = options

    query      = { namespace }
    query.type = type  if type?

    @remove query, callback


  @count = (options, callback) ->

    { namespace, type } = options

    query      = { namespace }
    query.type = type  if type?

    @one query, (err, counter) ->
      if err then callback err
      else callback null, counter?.current ? 0


  @setCount = (options, callback) ->

    { namespace, type, value } = options

    type ?= 'main'
    query = { namespace, type }

    operation = { $set: { current: value } }
    options   = { new: yes, upsert: yes }

    JCounter.findAndModify query, null, operation, options, handle callback
