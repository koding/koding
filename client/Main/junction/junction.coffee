class Junction extends KDObject

  constructor: (fields = []) ->
    super()

    @id = @createId()
    @fields = {}
    @children = {}

    @ordered = []
    @index = 0

    @addField field  for field in fields

  createId: KD.utils.createCounter()

  isJunction: yes

  getFields: (isDeep) ->
    if isDeep
      fields = @getFields()
      fields.push (child.getFields isDeep)... for own _, child of @children
      return fields

    (key for own key of @fields when not (key of @children))

  iterate: ->
    @index++
    @nextNode()

  nextNode: ->

    node = @ordered[@index]

    unless node? #cycle
      @index = 0

      return @nextNode() 

    if node.isJunction #fork

      if node.isSatisfied() #skip
        return @iterate()

      else
        if node.shouldPropagate() #propagate
          return node.nextNode()
        else
          return @iterate()

    @index++ #continue

    return node

  shouldPropagate: -> yes

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

    if field.isJunction

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
    satisfier = new Junction.Satisfier

    satisfier.on 'Satisfied', @bound 'report'
    satisfier.on 'Canceled',  @bound 'report'

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

  toString: -> "junction-#{@id}"

  @All = class All extends Junction
    # All is like Junction, but short-circuits propagation.
    shouldPropagate: ->
      if @dirty
        satisfied = @isSatisfied()
        return yes  if satisfied
        
        @dirty = no
        return no
      else
        @dirty = yes
        yes

  @Any = class Any extends Junction
    # Any is like Junction, with a couple tweaks.

    # Any#compliment negates the value :)
    compliment: (value) -> !value

    # Any#createSatisfier returns a singleton satisfier :)
    createSatisfier: -> @satisfier ?= super

  @all = (fields...) -> new All fields

  @any = (fields...) -> new Any fields 
