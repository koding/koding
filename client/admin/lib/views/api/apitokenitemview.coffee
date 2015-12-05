kd            = require 'kd'
JView         = require 'app/jview'
showError     = require 'app/util/showError'
KDModalView   = kd.ModalView
KDOverlayView = kd.OverlayView


module.exports = class ApiTokenItemView extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    @deleteButton = new kd.ButtonView
      title    : 'Delete'
      cssClass : 'solid medium red'
      callback : =>
        @delete()


  delete: ->

    apiToken = @getData()
    listView = @getDelegate()

    modal   = KDModalView.confirm
      title       : 'Remove stack'
      description : 'Do you want to remove ?'
      ok          :
        title     : 'Yes'
        callback  :  =>
          apiToken.remove (err) =>
            console.log this
            modal.destroy()
            listView.lazyBound 'deleteItem', this


  pistachio: ->

    """
      <div class="details">
        {p.fullname{ 'Code:' + #(code)} }
        {p.nickname{ '@' + #(username)} }
      </div>
      {div.role{> @deleteButton }}
    """
