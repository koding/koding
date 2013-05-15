JProduct = require '../product'

{Module} = require 'jraphical'

module.exports = class JBundle extends JProduct

  {dash} = require 'bongo'

  {extend} = require 'underscore'
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
        JLimit = require '../limit'

        queue = Object.keys(defaultLimits).map (limitName) => =>
          defaultOptions = defaultLimits[limitName]

          limitOptions = limits[limitName]

          limitOptions = { unit: limit }  if 'string' is typeof limitOptions

          limitOptions = extend { title: limitName }, defaultOptions, limitOptions

          limit = new JLimit limitOptions
          limit.save (err)=>
            return next err  if err
            @addLimit limit, limitName, fin

        dash queue, => @emit 'limitsAreSet'

        fin = queue.fin.bind queue

        return
