kd    = require 'kd'
JView = require 'app/jview'


module.exports = class StackTemplateListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "stacktemplate-item clearfix", options.cssClass
    super options, data

    delegate         = @getDelegate()
    { title, inuse } = @getData()

    @deleteButton = new kd.ButtonView
      cssClass : 'solid compact outline red secondary'
      title    : 'DELETE'
      callback : delegate.lazyBound 'deleteItem', this

    @showButton = new kd.ButtonView
      cssClass : 'solid compact outline secondary'
      title    : 'SHOW'
      callback : delegate.lazyBound 'showItemContent', this

    @updateButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'EDIT'
      callback : @bound 'updateStackTemplate'

    @inuseView = new kd.CustomHTMLView
      cssClass : 'inuse-tag'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This group currently using this template'

    @inuseView.hide()  unless inuse


  updateStackTemplate: ->
    @getDelegate().emit 'ItemSelected', @getData()


  pistachio: ->
    """
    <div class='stacktemplate-info clearfix'>
      {div.title{#(title)}} {{> @inuseView}}
    </div>
    <div class='buttons'>
      {{> @showButton}}{{> @deleteButton}}{{> @updateButton}}
    </div>
    """
