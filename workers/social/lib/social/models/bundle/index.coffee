JProduct = require '../product'

{Module} = require 'jraphical'

module.exports = class JBundle extends JProduct

  {dash} = require 'bongo'

  # @create = ()

  @setLimits = (limits) ->
    JLimit = require '../limit'

    relationships =
      limit         :
        targetType  : JLimit
        as          : (limitName for own limitName of limits)

    @setRelationships relationships

    # prevent subclasses from trying to set relationships + limits:
    @setRelationships = ->
      throw new Error "You can't set relationships on a bundle class"

    normalizedLimits = {}
    for own limitName, limit of limits
      normalizedLimits[limitName] =
        if 'string' is typeof limit then { unit: limit }
        else limit

    @limits_ = normalizedLimits

  constructor: (data, limits) ->

    super data

    if limits?

      { limits_: defaultLimits } = @constructor

      @once 'save', =>
        console.log 'does this happen?'

        queue = Object.keys(defaultLimits).map (limitName) => =>
          limitOptions = limits[limitName]
          limitOptions = { unit: limit }  if 'string' is typeof limitOptions
          limit = new Limit limitOptions
          limit.save (err)=>
            return next err  if err
            @addLimit limit, limitName, next

        dash queue, => @emit 'limitsAreSet'

        next = queue.next.bind queue

        return
