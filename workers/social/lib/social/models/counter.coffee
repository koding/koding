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

  update = (options, amount, callback) ->

    { namespace, type, max, min } = options

    type ?= 'main'
    query = { namespace, type }

    if amount > 0
      if max? and typeof max is 'number'
        query.current = { $lt: max }
    else
      if min? and typeof min is 'number'
        query.current = { $gt: min }

    operation = { $inc: { current: amount } }
    options   = { new: yes, upsert: yes }

    JCounter.findAndModify query, null, operation, options, (err, counter) ->
      if err
        if err.code is DUPLICATE_ERR
          callback new KodingError 'Provided limit has been reached'
        else
          callback err
      else
        callback null, counter.current


  # Private Methods
  # ---------------

  # Static Methods

  @increment = (options, callback) ->

    update options,  1, callback


  @decrement = (options, callback) ->

    update options, -1, callback


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
