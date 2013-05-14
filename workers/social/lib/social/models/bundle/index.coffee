{Module} = require 'jraphical'

module.exports = class JBundle extends Module

  {dash} = require 'bongo'

  @setLimits =(limits)->
    JLimit = require '../limit'

    relationships =
      limit         :
        targetType  : JLimit
        as          : (limitName for own limitName of limits)

    @setRelationships relationships

    normalizedLimits = {}
    for own limitName, limit of limits
      normalizedLimits[limitName] =
        if 'string' is typeof limit then { unit: limit }
        else limit

    @limits_ = normalizedLimits

  constructor:(limits)->
    super {}

    { limits_: defaultLimits } = @constructor

    @once 'save', =>

      queue = Object.keys(defaultLimits).map (limitName) => =>
        limitOptions = limits[limitName]
        limitOptions = { unit: limit }  if 'string' is typeof limitOptions
        limit = new Limit limitOptions
        limit.save (err)=>
          return next err  if err
          @addLimit limit, limitName, next

      next = queue.next.bind queue

      dash queue, => @emit 'limitsAreSet'
