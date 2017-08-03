kd = require 'kd'

showError = require 'app/util/showError'

module.exports = class CredentialForm extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-form', options.cssClass
    options.selectionPlaceholder ?= "Select #{options.title}"
    options.selectionLabel ?= "#{options.title} Selection"

    super options, data

    { title, selectionPlaceholder, selectionLabel } = @getOptions()
    { provider, fields } = @getData()

    @header = new kd.CustomHTMLView
      tagName  : 'h3'
      partial  : "#{title}:"

    @selectionLabel = new kd.LabelView
      title    : selectionLabel
      cssClass : 'selection-label'
    @selection      = new kd.SelectBox {
      label : @selectionLabel
      callback : @bound 'checkShowLinkVisibility'
    }

    { ui } = kd.singletons.computeController

    @showLink  = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'show-link'
      click    : =>
        { items } = @getData()

        selectedItem = @selection.getValue()
        return  if not selectedItem or @showLink.hasClass 'loading'

        @showLink.setClass 'loading'

        for item in items when item.identifier is selectedItem
          ui.showCredentialDetails {
            credential : item
            cssClass   : 'resources'
          }, @showLink.lazyBound 'unsetClass', 'loading'

          break

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
      partial  : "New #{title}:"
    @cancelNew = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'cancel-new'
      partial  : 'Cancel'
      click    : @bound 'onCancelNew'
    @newHeader.addSubView @cancelNew
    @newHeader.hide()

    @scroller = new kd.CustomScrollView()
    @scroller.wrapper.addSubView @getScrollableContent()

    @render()


  render: ->

    return  unless @selection

    { selectionPlaceholder } = @getOptions()
    { defaultItem, items } = @getData()

    selectOptions   = items.map (item) -> { value : item.identifier, title : item.title }
    selectOptions.unshift { value : '', title : selectionPlaceholder }

    selectedItem    = @selection.getValue() or defaultItem
    hasSelectedItem = (item for item in items when item.identifier is selectedItem).length > 0
    selectedItem    = ''  unless hasSelectedItem

    @selection.removeSelectOptions()
    @selection.setSelectOptions selectOptions
    @selection.setValue selectedItem

    @checkShowLinkVisibility()

    return @cancelNew.show()  if items.length > 0

    @onCreateNew()
    @cancelNew.hide()


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

    @unsetClass 'form-visible'
    @newHeader.hide()
    @header.show()


  selectValue: (value) ->

    @selection.setValue value
    @onCancelNew()


  setData: (data) ->

    super data

    # we need to update form even if parent page is not active at the moment
    # so that once parent page gets opened all new data is already in the place
    @render()  unless @parentIsInDom


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


  pistachio: ->

    '''
      {{> @header}}
      <div class='selection-container'>
        {{> @showLink}}
        {{> @selectionLabel}}
        {{> @selection}}
        {{> @createNew}}
      </div>
      {{> @newHeader}}
      <div class='form-container'>
        {{> @scroller}}
      </div>
    '''
