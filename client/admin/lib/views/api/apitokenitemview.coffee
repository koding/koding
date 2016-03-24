kd            = require 'kd'
JView         = require 'app/jview'
timeago       = require 'timeago'


module.exports = class APITokenItemView extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    listView = @getDelegate()

    deleteButtonOptions =
      title    : 'Delete'
      cssClass : 'solid compact red delete'
      callback : =>
        listView.emit 'ItemAction',
          action        : 'RemoveItem'
          item          : this
          options       :
            title       : 'Remove API Token'
            description : 'Do you want to remove ?'

    @deleteButton = new kd.ButtonView deleteButtonOptions


  pistachio: ->

    { createdAt } = @getData()

    """
      <div class="details">
        <p class="code">{code{#(code)}}</p>
        <p class="time">Created #{timeago createdAt} by {{#(username)}}</p>
      </div>
      {div.role{> @deleteButton }}
    """
