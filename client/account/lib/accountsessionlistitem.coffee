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
      callback : =>
        listView.emit 'ItemAction',
          action        : 'RemoveItem'
          item          : this
          options       :
            title       : 'Are you sure?'
            description : 'Do you really want to remove this session?'

    if data and kookies.get('clientId') is data.clientId
      deleteButtonOptions.tooltip = { title : 'This will log you out!', placement: 'left' }

    @deleteButton = new kd.ButtonView deleteButtonOptions


  pistachio: ->

    { groupName, lastAccess, lastLoginDate, clientId } = @getData()

    hostname = globals.config.domains.main

    group =
      if groupName is 'koding'
      then hostname
      else "#{groupName}.#{hostname}"

    activeSession = ''
    if kookies.get('clientId') is clientId
      group = "#{group} (Active)"
      activeSession = ' active'

    lastAccess = lastLoginDate or lastAccess

    """
    <div class="session-item">
      <div class="session-info">
        <p class="group-name#{activeSession}">#{group}</p>
        <p class="last-access">Last access: #{timeago lastAccess}</p>
      </div>
      {div.delete-button{> @deleteButton }}
    </div>
    """
