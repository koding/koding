class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data

    @collector = new FormWorkflow.Collector
    @collector.on 'Pending', @bound 'nextForm'
    @forwardEvent @collector, 'DataCollected'

    @forms      = {}
    @providers  = {}
    @active = null

    @history = new FormWorkflow.History

  isWorkflow: yes

  enter: -> @ready @bound 'nextForm'

  go: (direction) ->

    provider = do @history[direction]

    if provider.isWorkflow
      if (provider is @active and direction is 'back') or
         (direction is 'next')

        provider.go direction

    @showForm provider, no

  next: -> @go 'next'

  back: -> @go 'back'

  requireData: (fields) ->
    @collector.addRequirement fields

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
      @providers[field].push \
        if 'string' is typeof form
        then @forms[form]
        else form

    return this

  nextForm: ->
    provider = @nextProvider()
    @showForm provider  if provider?

  nextRequirement: -> @collector.nextRequirement()

  nextProvider: (key = @nextRequirement(), from) ->
    providers = @providers[key]
    providers.i = from ? providers.i ? 0
    provider = providers[providers.i++]
    return provider  if provider?

    try @nextProvider key, 0
    catch e
      throw e  unless e instanceof RangeError

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
    @forms[form]?.hide()  for form in forms

    return this

  showForm: (form, shouldPushState = yes) ->
    @hideForms()
    form = @getForm form
    form.show()
    form.activate? this

    @active = form

    @history.push form  if shouldPushState

    @emit 'FormIsShown', form

    return this

  addLoader:->
    @addSubView @loader = new KDLoaderView
      loaderOptions         :
        shape               : 'spiral'
        color               : '#a4a4a4'
      size                  :
        width               : 40
        height              : 40

  showLoader:-> @loader.show()
  hideLoader:-> @loader.hide()

  viewAppended:->
    @addLoader()
    @prepareWorkflow?()
    @emit 'ready'
    @hideLoader()

  skip: (data) ->
    v = new KDView
    v.activate = => @collectData data
    v

