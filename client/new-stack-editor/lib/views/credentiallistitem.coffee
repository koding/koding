kd = require 'kd'

Events = require '../events'
globals = require 'globals'


module.exports = class CredentialListItem extends kd.ListItemView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential', options.cssClass

    super options, data

    { provider } = @getData()
    providerColor = globals.config.providers[provider]?.color ? '#666666'

    handle = (action) => =>
      @getDelegate().emit 'ItemAction', { action, item: this }

    @checkBox = new kd.CheckBox
      defaultValue : off
      click: @bound 'handleChanges'

    @preview = new kd.ButtonView
      cssClass: 'show'
      callback: handle 'ShowItem'

    @delete = new kd.ButtonView
      cssClass: 'delete'
      callback: handle 'RemoveItem'

    @edit = new kd.ButtonView
      cssClass: 'edit'
      callback: handle 'EditItem'

    @provider    = new kd.CustomHTMLView
      cssClass   : 'provider'
      partial    : provider
      attributes :
        style    : "background-color: #{providerColor}"
      click      : (event) =>
        @getDelegate().emit Events.CredentialFilterChanged, provider
        kd.utils.stopDOMEvent event

    @on 'click', (event) =>
      unless 'checkbox' in event.target.classList
        @select not @isSelected(), userAction = yes
        kd.utils.stopDOMEvent event


  select: (state = yes, userAction = no) ->

    @checkBox.setValue state

    if state
    then @setClass   'selected'
    else @unsetClass 'selected'

    @handleChanges()  if userAction


  handleChanges: ->
    @getDelegate().emit Events.CredentialSelectionChanged, this, @isSelected()


  isSelected: ->
    @checkBox.getValue()


  verifyCredential: ->


  viewAppended: kd.View::viewAppended


  pistachio: ->

    '''
    {{> @checkBox}} {span.title{#(title)}}
    {{> @delete}} {{> @preview}}
    {{> @provider}}
    '''
