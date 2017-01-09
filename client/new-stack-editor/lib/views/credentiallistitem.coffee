kd = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential', options.cssClass

    super options, data

    handle = (action) => =>
      @getDelegate().emit 'ItemAction', { action, item: this }

    @checkBox = new kd.CustomCheckBox
      defaultValue : off

    @preview = new kd.ButtonView
      cssClass: 'show'
      callback: handle 'ShowItem'

    @delete = new kd.ButtonView
      cssClass: 'delete'
      callback: handle 'RemoveItem'

    @edit = new kd.ButtonView
      cssClass: 'edit'
      callback: handle 'EditItem'

    @on 'click', (event) =>
      unless 'checkbox' in event.target.classList
        @checkBox.setValue not !!@checkBox.getValue()
        kd.utils.stopDOMEvent event


  select: (state = yes) ->
    @checkBox.setValue state


  isSelected: ->
    @checkBox.getValue()


  pistachio: ->

    '''
    {{> @checkBox}} {span.title{ #(title)}}
    {{> @edit}} {{> @delete}} {{> @preview}}
    '''
