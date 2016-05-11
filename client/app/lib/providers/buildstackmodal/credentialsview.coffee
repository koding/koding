kd = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialsView extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'stack-credentials', options.cssClass

    super options, data

    { provider, selectedCredential } = @getOptions()
    items = @getData()

    selectOptions = items.map (item) -> { value : item.identifier, title : item.title }
    selectOptions.unshift { value : '', title : "Select #{provider} credential..." }
    defaultValue = selectedCredential ? ''
    @selectionLabel = new kd.LabelView { title : 'Credential Selection' }
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

    { computeController } = kd.singletons
    @form = computeController.ui.generateAddCredentialFormFor { provider }

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

    { provider } = @options
    title = "#{helper.getProviderName provider} Credential:"

    """
      <div class='form-header'>#{title}</div>
      <div class='selection-container'>
        {{> @selectionLabel}}
        {{> @selection}}
      </div>
      {{> @createNew}}
      <div class='form-container'>
        <div class='form-header new-credential-header'>
          New #{helper.getProviderName provider} Credential:
          {{> @cancelNew}}
        </div>
        {{> @form}}
      </div>
    """


  helper =

    getProviderName: (provider) ->

      switch provider
        when 'aws' then provider.toUpperCase()
        else provider[0].toUpperCase() + provider.substring 1
