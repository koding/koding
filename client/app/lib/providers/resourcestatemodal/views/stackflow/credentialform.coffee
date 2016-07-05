kd = require 'kd'
JView = require 'app/jview'
showError = require 'app/util/showError'

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
      callback : @bound 'checkShowLinkVisibility'
    }

    { ui } = kd.singletons.computeController

    @showLink  = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'show-link'
      click    : =>

        selectedItem = @selection.getValue()
        return  if not selectedItem or @showLink.hasClass 'loading'

        @showLink.setClass 'loading'

        for item in items when item.identifier is selectedItem
          ui.showCredentialDetails {
            credential : item
            cssClass   : 'resources'
          }, @showLink.lazyBound 'unsetClass', 'loading'

          break

    @checkShowLinkVisibility()

    @createNew = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'create-new'
      partial  : '<span class="plus">+</span> Create New'
      click    : @bound 'onCreateNew'

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


  checkShowLinkVisibility: ->

    { items } = @getData()
    selectedItem = @selection.getValue()

    return @showLink.hide()  unless selectedItem

    isLocked = (
      item for item in items when item.identifier is selectedItem and item.isLocked
    ).length > 0

    if isLocked
    then @showLink.hide()
    else @showLink.show()


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
        {{> @showLink}}
        {{> @selection}}
        {{> @createNew}}
      </div>
      {{> @newHeader}}
      <div class='form-container'>
        {{> @scroller}}
      </div>
    """
