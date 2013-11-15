class FormWorkflow extends KDView

  make = ->
    fw = new FormWorkflow
    fw.on 'DataCollected', -> log arguments
    fw

  assert = (truth) ->
    unless !!truth
      

      { stack } = new Error

      debugger

      throw {
        message: "Assertion error!", stack
      }

  tests = [
    ->
      @requireData [
        'foo'
        'bar'
      ]
      
      @collectData { foo: 42 }
      
      assert not @isSatisfied()
      
      @collectData { bar: 0 }
      
      assert @isSatisfied()
    
    ->
      @requireData @all(
        'foo'
        'bar'
      )
      
      @collectData { foo: 42 }
      
      assert not @isSatisfied()
      
      @collectData { bar: 0 }
      
      assert @isSatisfied()

    ->
      @requireData @any(
        'foo'
        'bar'
      )
      
      @collectData { foo: 42 }
      
      assert @isSatisfied()
      
      @collectData { bar: 0 }
      
      assert @isSatisfied()

      @clearData 'foo'

      assert @isSatisfied()

      @clearData 'bar'

      assert not @isSatisfied()
    ->
      @requireData @all(
        'foo'
        'bar'
        @any('baz', 'qux')
      )
      
      @collectData { foo: 42 }
      
      assert not @isSatisfied()
      
      @collectData { bar: 0 }
      
      assert not @isSatisfied()

      @collectData { baz: 16 }

      assert @isSatisfied()

      @clearData 'baz'

      assert not @isSatisfied()

      @collectData { qux: -88 }

      assert @isSatisfied()

      @clearData 'bar'

      assert not @isSatisfied()


  ]

  @runTests = ->
    test.call make()  for test in tests

    return this


  constructor: (options = {}, data) ->
    super options, data
    @forms = {}
    @collector = new Collector
    @collector.on 'RequirementSatisfied', @bound 'nextForm'
    @forwardEvent @collector, 'DataCollected'
    @providers = {}

  requireData: (fields) ->
    gate =
      if fields.isGate
      then fields
      else @all fields...

    @collector.addRequirement gate

    return this

  getData: -> @data

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

  @Collector = class Collector extends KDEventEmitter

    constructor: (@gate = new Gate) ->
      super
      @data = {}
      @gate.on 'report', (state) => switch state
        when 'Satisfied'
          @emit 'DataCollected', @data
        when 'Dissatisfied' then # ignore

    addRequirement: (requirement) ->
      @gate.addField requirement

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

    isSatisfied: -> @satisfied ?= no

    satisfy: ->
      @satisfied = yes
      @emit 'Satisfied'

    cancel: ->
      @satisfied = no
      @emit 'Canceled'

  @Gate = class Gate extends KDObject

    constructor: (fields = []) ->
      super()

      @id = @createId()
      @fields = {}
      @children = []
      @addField field  for field in fields

    createId: do (i = 0) -> -> i++

    isGate: yes

    getFields: -> Object.keys @fields

    addChild: (child) ->
      @children.push child
      return this

    removeChild: (child) ->
      @children.splice i, 0  while (i = @children.indexOf child) > -1
      return this

    addField: (field) ->
      satisfier = @createSatisfier()
      
      @fields[field] = satisfier

      if field.isGate

        @addChild field
        
        field.on 'report', (state) => switch state
          when 'Satisfied'
            @emit 'RequirementSatisfied', field
            satisfier.satisfy()
          when 'Canceled' then # ignore
            # satisfier.cancel()

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

    createSatisfier: ->
      satisfier = new Satisfier

      satisfier.on 'Satisfied', @bound 'report'
      satisfier.on 'Canceled', @bound 'report'

      return satisfier

    report: ->
      @emit 'report', if @isSatisfied() then 'Satisfied' else 'Dissatisfied'

      return this

    kill: -> @compliment no

    compliment: (value) -> value

    isSatisfied: ->
      for own _, field of @fields
        return @kill()  unless @compliment field.isSatisfied()

      for child in @children
        return @kill()  unless @compliment child.isSatisfied()

      return !@kill()

    toString: -> "gate-#{@id}"

  @All = class All extends Gate
    # All is like Gate.

  @Any = class Any extends Gate
    # Any is like Gate, with a couple tweaks.

    # Any#compliment negates the value :)
    compliment: (value) -> !value

    # Any#createSatisfier returns a singleton satisfier :)
    createSatisfier: -> @satisfier ?= super()
