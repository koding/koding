class FormWorkflow.Gate extends KDObject

  constructor: (fields = []) ->
    super()

    @id = @createId()
    @fields = {}
    @children = {}

    @ordered = []
    @index = 0

    @addField field  for field in fields

  createId: KD.utils.createCounter()

  isGate: yes

  getFields: (isDeep) ->
    if isDeep
      fields = @getFields()
      fields.push (child.getFields yes)... for own _, child of @children
      return fields

    (key for own key of @fields when not (key of @children))

  nextNode: ->
    node = @ordered[@index]

    unless node? #cycle
      @index = 0

      return @nextNode() 

    if node.isGate #fork

      if node.isSatisfied() #skip
        @index++

        return @nextNode()

      else #propagate
        return node.nextNode()

    @index++ #continue

    return node

  addChild: (child) ->
    @children[child] = child

    return this

  removeChild: (child) ->
    delete @children[child]

    return this

  addField: (field) ->
    @ordered.push field

    satisfier = @createSatisfier()
    
    @fields[field] = satisfier

    if field.isGate

      @addChild field

      field.on 'status', (isSatisfied) ->
        if isSatisfied
        then satisfier.satisfy()
        else satisfier.cancel()

    return this

  removeKey: (key) ->
    if key of @fields
      @index = 0
      @fields[key].cancel()
    else
      child.removeKey key  for own _, child of @children

    return this

  satisfy: (field) ->
    satisfier.satisfy()  if (satisfier = @fields[field])?

    child.satisfy field  for own _, child of @children

    return this

  createSatisfier: ->
    satisfier = new FormWorkflow.Gate.Satisfier

    satisfier.on 'Satisfied', @bound 'report'
    satisfier.on 'Canceled', @bound 'report'

    return satisfier

  report: ->
    @emit 'status', @isSatisfied()

    return this

  kill: -> @compliment no

  compliment: (value) -> value

  isSatisfied: ->
    for category in [@fields, @children]
      for own _, node of category when not @compliment node.isSatisfied()
        return @kill()

    return not @kill()

  toString: -> "gate-#{@id}"


  @All = class All extends this
    # All is like Gate.

  @Any = class Any extends this
    # Any is like Gate, with a couple tweaks.

    # Any#compliment negates the value :)
    compliment: (value) -> !value

    # Any#createSatisfier returns a singleton satisfier :)
    createSatisfier: -> @satisfier ?= super
