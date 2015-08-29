kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CustomDataListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry \
      'credential-item customdata-item clearfix', options.cssClass

    super options, data

    delegate          = @getDelegate()
    { title, fields } = @getData()

    @deleteButton = new kd.ButtonView
      cssClass : 'solid compact outline red secondary'
      title    : 'DELETE'
      callback : delegate.lazyBound 'deleteItem', this

    @showButton = new kd.ButtonView
      cssClass : 'solid compact outline secondary'
      title    : 'SHOW'
      callback : delegate.lazyBound 'showItemContent', this

    @selectButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'USE THIS'
      loader   :
        color  : '#666'
      callback : @getDelegate().lazyBound 'emit', 'ItemSelected', @getData()


  pistachio: ->
    """
    <div class='credential-info clearfix'>
      {div.title{#(title)}}
      <div class='fields'>Includes information for:
        <strong>{{#(fields)}}</strong>
      </div>
    </div>
    <div class='buttons'>
      {{> @showButton}}{{> @deleteButton}}{{> @selectButton}}
    </div>
    """
