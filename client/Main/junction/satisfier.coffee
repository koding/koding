class Junction.Satisfier extends KDEventEmitter

  constructor: ->
    super()
    @satisfied = 0

  isSatisfied: -> @satisfied > 0

  satisfy: ->
    @satisfied++
    @emit 'Satisfied'

  cancel: ->
    @satisfied = Math.max @satisfied - 1, 0
    @emit 'Canceled'
