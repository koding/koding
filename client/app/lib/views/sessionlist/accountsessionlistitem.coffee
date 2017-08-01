kd             = require 'kd'

globals        = require 'globals'
kookies        = require 'kookies'
timeago        = require 'timeago'
KDListItemView = kd.ListItemView


module.exports = class AccountSessionListItem extends KDListItemView


  constructor: (options = {}, data) ->

    super options, data
    listView = @getDelegate()

    deleteButtonOptions =
      title    : 'Log Out'
      cssClass : 'solid compact delete'
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


  viewAppended: kd.View::viewAppended


  pistachio: ->

    { groupName, lastAccess, lastLoginDate, clientId, sessionData } = @getData()

    hostname = globals.config.domains.main

    group =
      if groupName is 'koding'
      then hostname
      else "#{groupName}.#{hostname}"

    lastAccess = lastLoginDate or lastAccess

    if kookies.get('clientId') is clientId
      cssClass = 'active'

    if sessionData?.apiSession
      cssClass = 'api'

    @session = new kd.CustomHTMLView
      cssClass: 'group-name'
      partial: group


    """
    <div class="session-item">
      <div class='session-info'>
        <div class="#{cssClass}">
          {{> @session}}
        </div>
        <p class="last-access">Last access: #{timeago lastAccess}</p>
      </div>
      {div.delete-button{> @deleteButton }}
    </div>
    """
