kd             = require 'kd'
JView          = require 'app/jview'
globals        = require 'globals'
kookies        = require 'kookies'
timeago        = require 'timeago'
KDListItemView = kd.ListItemView


module.exports = class AccountSessionListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data
    listView = @getDelegate()

    deleteButtonOptions =
      title    : 'Terminate'
      cssClass : 'solid compact red delete'
      callback : listView.lazyBound 'deleteItem', this

    if kookies.get('clientId') is data.clientId
      deleteButtonOptions.tooltip = { title : 'This will log you out!', placement: 'left' }

    @deleteButton = new kd.ButtonView deleteButtonOptions


  pistachio: ->

    { groupName, lastAccess } = @getData()

    hostname = switch globals.config.environment
      when 'production' then 'koding.com'
      else "#{globals.config.environment}.koding.com"

    group =
      if groupName is 'koding'
      then hostname
      else "#{groupName}.#{hostname}"

    """
    <div class="session-item">
      <div class="session-info">
        <p class="group-name">#{group}</p>
        <p class="last-access">Last access: #{timeago lastAccess}</p>
      </div>
      {div.delete-button{> @deleteButton }}
    </div>
    """

