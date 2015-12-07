kd            = require 'kd'
JView         = require 'app/jview'
showError     = require 'app/util/showError'
KDModalView   = kd.ModalView
KDOverlayView = kd.OverlayView
timeago       = require 'timeago'


module.exports = class APITokenItemView extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    listView = @getDelegate()

    @deleteButton = new kd.ButtonView
      title    : 'Delete'
      cssClass : 'solid compact red delete'
      callback : listView.lazyBound 'deleteItem', this


  pistachio: ->

    { createdAt } = @getData()

    """
      <div class="details">
        <p class="code">{code{#(code)}}</p>
        <p class="time">Created #{timeago createdAt} by {{#(username)}}</p>
      </div>
      {div.role{> @deleteButton }}
    """
