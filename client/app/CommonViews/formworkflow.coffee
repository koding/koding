class FormWorkflow extends KDView

  constructor: (options = {}, data) ->
    super options, data
    @forms = {}

  addForm: (formName, form) ->
    @forms[formName] = form
    @addSubView form
    form.hide()

  removeForm: (form) ->
    form = @getForm form
    @removeSubView form
    delete @forms[form]

  getForm: (form) ->
    if 'string' is typeof form
    then @forms[form]
    else form

  getFormNames: -> Object.keys @forms

  hideForms: (forms = @getFormNames()) ->
    @forms[form]?.hide() for form in forms

  showForm: (form) ->
    form = @getForm form
    @hideForms()
    form.show()