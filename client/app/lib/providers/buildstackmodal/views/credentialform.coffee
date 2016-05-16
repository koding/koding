kd = require 'kd'
JView = require 'app/jview'

module.exports = class CredentialForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-form', options.cssClass
    options.selectionPlaceholder ?= "Select #{options.title}"
    options.selectionLabel ?= "#{options.title} Selection"

    super options, data

    @createViews()


  createViews: ->

    { title, selectionPlaceholder, selectionLabel } = @getOptions()
    { provider, fields, selectedItem, items } = @getData()

    selectOptions = items.map (item) -> { value : item.identifier, title : item.title }
    selectOptions.unshift { value : '', title : selectionPlaceholder }
    defaultValue = selectedItem ? ''
    @selectionLabel = new kd.LabelView { title : selectionLabel }
    @selection = new kd.SelectBox {
      selectOptions
      defaultValue
      label : @selectionLabel
    }

    @createNew = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'create-new'
      partial  : '<span class="plus">+</span> Create New'
      click    : @bound 'onCreateNew'

    { ui } = kd.singletons.computeController
    @form  = ui.generateAddCredentialFormFor {
      provider
      requiredFields : fields
      callback       : @bound 'onFormValidated'
    }
    @forwardEvent @form, 'FormValidationFailed'

    @cancelNew = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'cancel-new'
      partial  : 'Cancel'
      click    : @bound 'onCancelNew'

    if items.length > 0
      @setClass 'selection-visible'
    else
      @onCreateNew()


  onCreateNew: -> @setClass 'form-visible'


  onCancelNew: -> @unsetClass 'form-visible'


  validate: ->

    @selection.unsetClass 'validation-error'

    if @hasClass 'form-visible'
      @form.submit()
    else if selectedItem = @selection.getValue()
      { provider } = @getData()
      @emit 'FormValidationPassed', { provider, selectedItem }
    else
      @selection.setClass 'validation-error'
      @emit 'FormValidationFailed'


  onFormValidated: (title, fields) ->

    { provider } = @getData()
    @emit 'FormValidationPassed', { provider, newData : { title, fields } }


  render: ->

    @unsetClass 'form-visible'
    @unsetClass 'selection-visible'
    @destroySubViews()
    @clear()

    @createViews()
    @viewAppended()


  pistachio: ->

    { title } = @getOptions()

    """
      <h3 class='top-header'>#{title}:</h3>
      <div class='selection-container'>
        {{> @selectionLabel}}
        {{> @selection}}
      </div>
      {{> @createNew}}
      <div class='form-container'>
        <h3 class='new-credential-header'>
          New #{title}:
          {{> @cancelNew}}
        </h3>
        {{> @form}}
      </div>
    """
