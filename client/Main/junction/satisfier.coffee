class Junction.Satisfier extends KDEventEmitter

  constructor: ->
    super()
    @dirty = no
    @satisfied = 0

  isSatisfied: -> @satisfied > 0

  isDirty: -> @dirty

  satisfy: ->
    @dirty = yes
    @satisfied++
    @emit 'Satisfied'

  cancel: ->
    @dirty = yes
    @satisfied = Math.max @satisfied - 1, 0
    @emit 'Canceled'
