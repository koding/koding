kd = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialForm extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-form', options.cssClass
    options.selectionPlaceholder ?= "Select #{options.title}"

    super options, data

    { title, selectionPlaceholder } = @getOptions()
    { provider, fields, selectedItem, items } = @getData()

    selectOptions = items.map (item) -> { value : item.identifier, title : item.title }
    selectOptions.unshift { value : '', title : selectionPlaceholder }
    defaultValue = selectedItem ? ''
    @selectionLabel = new kd.LabelView { title }
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
    @form  = ui.generateAddCredentialFormFor { provider, requiredFields : fields }

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


  pistachio: ->

    { title } = @getOptions()

    """
      <div class='form-header'>#{title}</div>
      <div class='selection-container'>
        {{> @selectionLabel}}
        {{> @selection}}
      </div>
      {{> @createNew}}
      <div class='form-container'>
        <div class='form-header new-credential-header'>
          New #{title}
          {{> @cancelNew}}
        </div>
        {{> @form}}
      </div>
    """
