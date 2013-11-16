class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data
    @forms = {}
    @collector = new Collector
    @forwardEvent @collector, 'DataCollected'
    @providers = {}

  requireData: (fields) ->
    gate =
      if fields.isGate
      then fields
      else @all fields...

    @collector.addRequirement gate

    return this

  getFields: (isDeep) -> @collector.getFields isDeep

  getData: -> @collector.data

  isSatisfied: -> 
    @collector.gate.isSatisfied()

  collectData: (data) ->
    @collector.collectData data

    return this

  clearData: (key) ->
    @collector.removeKey key

    return this

  provideData: (form, provides) ->
    for field in provides
      @providers[field] ?= []
      @providers[field].push(
        if 'string' is typeof form
        then @forms[form]
        else form
      )

  nextForm: ->
    requirement = @nextRequirement()
    console.log { requirement, t: this }
    debugger

  nextRequirement: ->
    @collector.nextRequirement()

  nextProvider: (key) ->
    providers = @providers[key]
    providers.i ?= 0
    providers[providers.i++]

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
    form.show()
    @emit 'FormIsShown', form
    return this

  all: (fields...) -> new All fields
  any: (fields...) -> new Any fields

  @Collector = class Collector extends KDEventEmitter

    constructor: (@gate = new Gate) ->
      super
      @data = {}
      @gate.on 'NextForm', => @emit 'NextForm'
      @gate.on 'report', (isSatisfied) =>
        @emit 'DataCollected', @data  if isSatisfied

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

    constructor: (@tag) ->
      super()
      @satisfied = 0

    isSatisfied: -> @satisfied > 0

    satisfy: ->
      @satisfied++
      @emit 'Satisfied'

    cancel: ->
      @satisfied--
      @emit 'Canceled'

  @Gate = class Gate extends KDObject

    constructor: (fields = []) ->
      super()

      @id = @createId()
      @fields = {}
      @childrenByKey = {}
      @addField field  for field in fields

    createId: do (i = 0) -> -> i++

    isGate: yes

    getFields: (isDeep) ->
      if isDeep
        fields = @getFields()
        fields.push (child.getFields yes)... for own _, child of @childrenByKey
        return fields
      else
        (key for own key of @fields when not (key of @childrenByKey))

    nextNode: ->
      for field in @getFields yes
        return field  if field of @fields and not @fields[field].isSatisfied()

      for own _, child of @childrenByKey
        return childNode  if (childNode = child.nextNode())? 

      null
      # node = @pending.nodes.shift()
      # return node  if node
      # child = @pending.children[0]
      # child = @nextChild()  while child?.isSatisfied()
      # return null  unless child
      # node = child.nextNode()
      # return node  if node
      # @nextChild()
      # @nextNode()

    # nextChild: -> @pending.children.shift()

    addChild: (child) ->
      @childrenByKey[child] = child
      return this

    # addNode: (node) ->
    #   @pending.nodes.push node

    removeChild: (child) ->
      delete @childrenByKey[child]
      return this

    addField: (field) ->
      satisfier = @createSatisfier "#{ field }"
      
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
        @fields[key].cancel()
      else
        child.removeKey key  for own _, child of @childrenByKey

      return this

    satisfy: (field) ->
      if (satisfier = @fields[field])?
        satisfier.satisfy()
      else
        child.satisfy field  for own _, child of @childrenByKey

      return this

    createSatisfier: (tag) ->
      satisfier = new Satisfier tag

      satisfier.on 'Satisfied', @bound 'report'
      satisfier.on 'Canceled', @bound 'report'

      return satisfier

    report: ->
      @emit 'status', @isSatisfied()

      return this

    kill: -> @compliment no

    compliment: (value) -> value

    isSatisfied: ->
      for collection in [@fields, @childrenByKey]
        for own _, field of collection
          return @kill()  unless @compliment field.isSatisfied()

      return !@kill()

    toString: -> "gate-#{@id}"

  @All = class All extends Gate
    # All is like Gate.

  @Any = class Any extends Gate
    # Any is like Gate, with a couple tweaks.

    # Any#compliment negates the value :)
    compliment: (value) -> !value

    # Any#createSatisfier returns a singleton satisfier :)
    createSatisfier: (tag) -> @satisfier ?= super tag
