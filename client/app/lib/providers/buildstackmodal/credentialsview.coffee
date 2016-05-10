kd = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialsView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'stack-credentials', options.cssClass
    options.title   ?= 'AWS Credential:'

    super options, data

    { provider, selectedCredential } = @getOptions()
    items = @getData()

    @selection = new kd.SelectBox()
    selectedOptions = items.map (item) -> { value : item.identifier, title : item.title }
    selectedOptions.unshift { value : '', title : "Select #{provider} credential..." }
    @selection.setSelectOptions selectedOptions
    @selection.setDefaultValue selectedCredential  if selectedCredential

  pistachio: ->

    { title } = @options

    """
      <div class='credentials-title'>#{title}</div>
      {{> @selection}}
    """
