class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data

    @collector = new FormWorkflow.Collector
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

  nextForm: -> try @showForm @nextProvider()

  nextRequirement: -> @collector.nextRequirement()

  nextProvider: (key = @nextRequirement(), from) ->
    providers = @providers[key]
    providers.i = from ? providers.i ? 0
    provider = providers[providers.i++]
    return provider  if provider?

    try @nextProvider key, 0

  addForm: (formName, form, provides = []) ->
    @forms[formName] = form
    @addSubView form
    form.hide()
    @forwardEvent form, 'Cancel'
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

  all: (fields...) -> new FormWorkflow.Gate.All fields
  any: (fields...) -> new FormWorkflow.Gate.Any fields

  viewAppended:->
    @prepareWorkflow?()
    @emit 'ready'
