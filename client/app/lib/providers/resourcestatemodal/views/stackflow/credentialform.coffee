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

    { title, hideTitle, selectionPlaceholder, selectionLabel } = @getOptions()
    { provider, fields, selectedItem, items } = @getData()

    @header = new kd.CustomHTMLView
      tagName  : 'h3'
      partial  : title
    @header.hide()  if hideTitle

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

    @newHeader = new kd.CustomHTMLView
      tagName  : 'h3'
      partial  : "New #{title}"
    @cancelNew = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'cancel-new'
      partial  : 'Cancel'
      click    : @bound 'onCancelNew'
    @newHeader.addSubView @cancelNew
    @newHeader.hide()

    @scroller = new kd.CustomScrollView()
    @scroller.wrapper.addSubView @getScrollableContent()

    if items.length > 0
      @unsetClass 'form-visible'
    else
      @setClass 'form-visible'


  getScrollableContent: -> @form


  onCreateNew: ->

    { title } = @getOptions()

    @setClass 'form-visible'
    @newHeader.show()
    @header.hide()


  onCancelNew: ->

    { hideTitle } = @getOptions()

    @unsetClass 'form-visible'
    @newHeader.hide()
    @header.show()  unless hideTitle


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
      {{> @header}}
      <div class='selection-container'>
        {{> @selectionLabel}}
        {{> @selection}}
        {{> @createNew}}
      </div>
      {{> @newHeader}}
      <div class='form-container'>
        {{> @scroller}}
      </div>
    """
