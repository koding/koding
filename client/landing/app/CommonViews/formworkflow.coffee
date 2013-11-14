class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data
    @forms = {}
    @requiredData = {}
    @collectedData = {}

  requireData: (fields) ->
    for field in fields
      @requiredData[field] = no
    return this

  collectData: (data) ->
    # collect those data
    @collectedData[field] = value  for own field, value of data
    # remove the requirement to collect those data
    delete @requiredData[field]
    # return if there are more data required to collect
    return this  for own _ of @requiredData
    # otherwise, we are done, emit the "DataCollected" event
    @emit 'DataCollected', @collectedData
    return this

  clearData: (key) ->
    @requiredData[key] = no
    delete @collectedData[key]
    return this

  addForm: (formName, form) ->
    @forms[formName] = form
    @addSubView form
    form.hide()
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