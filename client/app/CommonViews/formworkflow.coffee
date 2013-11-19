class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data

    @collector = new Collector
    @collector.on 'Pending', @bound 'nextForm'
    @forwardEvent @collector, 'DataCollected'

    @forms      = {}
    @providers  = {}

  enter: -> @ready @bound 'nextForm'

  requireData: (fields, mode = 'all') ->
    gate =
      if fields.isGate
      then fields
      else @[mode] fields...

    @collector.addRequirement gate

    return this

  getFields: (isDeep) -> @collector.getFields isDeep

  getData: -> @collector.data

  isSatisfied: -> @collector.gate.isSatisfied()

  collectData: (data) ->
    @collector.collectData data

    return this

  clearData: (key) ->
    @collector.removeKey key

    return this

  provideData: (form, providers) ->
    for field in providers
      @providers[field] ?= []
      @providers[field].push(
        if 'string' is typeof form
        then @forms[form]
        else form
      )

    return this

  nextForm: ->
    requirement = @nextRequirement()
    return  unless requirement?
    
    provider = @nextProvider requirement
    return  unless provider?

    @showForm provider

    return provider

  nextRequirement: -> @collector.nextRequirement()

  nextProvider: (key, from) ->
    providers = @providers[key]
    providers.i = from ? providers.i ? 0
    provider = providers[providers.i++]
    return provider  if provider?

    try @nextProvider key, 0

  addForm: (formName, form, provides = []) ->
    @forms[formName] = form
    @addSubView form
    form.hide()
    @provideData formName, provides
    return this

  removeForm: (form) ->
    form = @getForm form
    @removeSubView form
    delete @forms[form]
    return this

  getForm: (form) ->
    if 'string' is typeof form
    then @forms[form]
    else form

  getFormNames: -> Object.keys @forms

  hideForms: (forms = @getFormNames()) ->
    @forms[form]?.hide() for form in forms
    return this

  showForm: (form) ->
    @hideForms()
    form = @getForm form
    form.activate? this
    form.show()
    return this

  all: (fields...) -> new All fields
  any: (fields...) -> new Any fields

  viewAppended:->
    @prepareWorkflow?()
    @emit 'ready'

  @Collector = class Collector extends KDEventEmitter

    constructor: (@gate = new Gate) ->
      super
      @data = {}

      @gate.on 'status', (isSatisfied) =>
        if isSatisfied
          @emit 'DataCollected', @data
        else
          @emit 'Pending'

    addRequirement: (requirement) ->
      @gate.addField requirement

    nextRequirement: -> @gate.nextNode()

    getFields: (isDeep) -> @gate.getFields isDeep

    getData: -> @data

    collectData: (data) ->
      @defineKey key, val  for own key, val of data

    removeKey: (key) ->
      delete @data[key]
      @gate.removeKey key

    defineKey: (key, value) ->
      @data[key] = value
      @gate.satisfy key

  @Satisfier = class Satisfier extends KDEventEmitter

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

  @Gate = class Gate extends KDObject

    constructor: (fields = []) ->
      super()

      @id = @createId()
      @fields = {}
      @children = {}

      @ordered = []
      @index = 0

      @addField field  for field in fields

    createId: do (i = 0) -> -> i++

    isGate: yes

    getFields: (isDeep) ->
      if isDeep
        fields = @getFields()
        fields.push (child.getFields yes)... for own _, child of @children
        return fields
      else
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
      satisfier = new Satisfier

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

  @All = class All extends Gate
    # All is like Gate.

  @Any = class Any extends Gate
    # Any is like Gate, with a couple tweaks.

    # Any#compliment negates the value :)
    compliment: (value) -> !value

    # Any#createSatisfier returns a singleton satisfier :)
    createSatisfier: -> @satisfier ?= super
