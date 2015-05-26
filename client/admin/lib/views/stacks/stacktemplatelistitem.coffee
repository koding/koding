kd    = require 'kd'
JView = require 'app/jview'


module.exports = class StackTemplateListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "stacktemplate-item clearfix", options.cssClass
    super options, data

    delegate  = @getDelegate()
    { title } = @getData()

    @deleteButton = new kd.ButtonView
      cssClass : 'solid compact outline red secondary'
      title    : 'DELETE'
      callback : delegate.lazyBound 'deleteItem', this

    @updateButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'UPDATE'
      callback : @bound 'updateStackTemplate'


  updateStackTemplate: ->
    @getDelegate().emit 'ItemSelected', @getData()


  pistachio: ->
    """
    <div class='stacktemplate-info clearfix'>
      {div.title{#(title)}}
    </div>
    <div class='buttons'>
      {{> @deleteButton}}{{> @updateButton}}
    </div>
    """
