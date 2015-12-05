kd            = require 'kd'
JView         = require 'app/jview'
showError     = require 'app/util/showError'
KDModalView   = kd.ModalView
KDOverlayView = kd.OverlayView


module.exports = class APITokenItemView extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    listView = @getDelegate()

    @deleteButton = new kd.ButtonView
      title    : 'Delete'
      cssClass : 'solid medium red'
      callback : listView.lazyBound 'deleteItem', this


  pistachio: ->

    """
      <div class="details">
        {p.fullname{ 'Code:' + #(code)} }
        {p.nickname{ '@' + #(username)} }
      </div>
      {div.role{> @deleteButton }}
    """
