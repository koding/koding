class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data
    @forms = {}
    @collector = new Collector
    @collector.on 'RequirementSatisfied', @bound 'nextForm'
    @forwardEvent @collector, 'DataCollected'
    @providers = {}

  requireData: (fields) ->
    gate =
      if (fields.hasBrand? 'all') or (fields.hasBrand? 'any')
      then fields
      else @all fields...

    @collector.addRequirement gate

    return this

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
    debugger

  nextProvider: (key) ->
    providers = @providers[field]
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
    return this

  all: (fields...) -> new All fields
  any: (fields...) -> new Any fields

  class Collector extends KDEventEmitter

    constructor: (@gate = new All) ->
      super
      @data = {}
      @gate.on 'Satisfied', => @emit 'DataCollected', @data

    addRequirement: (requirement) ->
      @gate.addField requirement

    satisfyRequirement: (key) ->
      @gate.satisfy key

    collectData: (data) ->
      @defineKey key, val  for own key, val of data

    removeKey: (key) ->
      delete @data[key]
      @gate.removeKey key

    defineKey: (key, value) ->
      @data[key] = value
      @satisfyRequirement key

  class Satisfier extends KDEventEmitter

    isSatisfied: -> @satisfied ?= no

    satisfy: ->
      @satisfied = yes
      @emit 'Satisfied'

    cancel: ->
      @satisfied = no
      @emit 'Canceled'

  class Gate extends KDObject

    makeError = (message, brand) ->
      { stack } = new Error
      {
        message, brand, stack
      }

    constructor: (@brand, fields = []) ->
      unless @brand in ['any', 'all']
        throw makeError 'Unrecognized brand!', @brand

      super()

      @id = @createId()
      @fields = {}
      @children = []
      @addField field  for field in fields

    createId: do (i = 0) -> -> i++

    getFields: -> Object.keys @fields

    addChild: (child) ->
      @children.push child
      return this

    removeChild: (child) ->
      i = @children.indexOf child
      @children.splice i  if i > -1
      return this

    addField: (field) ->
      satisfier = @getSatisfier()
      
      @fields[field] = satisfier

      unless 'string' is typeof field
        @addChild field
        
        field.on 'Satisfied', =>
          debugger
          @emit 'RequirementSatisfied', field
          satisfier.satisfy()

        field.on 'Canceled', ->
          satisfier.cancel()

      return this

    removeKey: (key) ->
      if key of @fields
        @fields[key].cancel()
      else
        child.removeKey key  for child in @children
      return this

    satisfy: (field) ->
      if (satisfier = @fields[field])?
        satisfier.satisfy()
      else
        child.satisfy field  for child in @children
      return this

    getSatisfier: -> switch @brand
      when 'any'  then @satisfier ?= @createSatisfier()
      when 'all'  then @createSatisfier()

    report: ->
      @emit if @isSatisfied() then 'Satisfied' else 'Dissatisfied'
      return this

    createSatisfier: ->
      satisfier = new Satisfier

      satisfier.on 'Satisfied', @bound 'report'
      satisfier.on 'Canceled', @bound 'report'

      return satisfier

    hasBrand: (brand) -> brand is @brand

    getSignal: -> @compliment no

    compliment: (value) -> switch @brand
      when 'all' then value
      when 'any' then !value

    isSatisfied: ->
      for own _, field of @fields
        return @getSignal()  unless @compliment field.isSatisfied()

      for child in @children
        return @getSignal()  unless @compliment child.isSatisfied()

      return !@getSignal()

    toString: -> "gate-#{@id}"

  class All extends Gate
    constructor: (fields) -> super 'all', fields

  class Any extends Gate
    constructor: (fields) -> super 'any', fields
