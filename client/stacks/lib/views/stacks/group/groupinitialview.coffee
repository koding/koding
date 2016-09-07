kd                = require 'kd'
BaseInitialView   = require '../baseinitialview'


module.exports = class GroupInitialView extends BaseInitialView


  constructor: (options = {}, data) ->

    options.listViewOptions =
      viewType              : 'group'

    super options, data


  pistachio: ->

    { groupsController } = kd.singletons

    @createStackButton = if groupsController.canEditGroup() then @button
    else new kd.CustomHTMLView

    """
    <div class='text header'>Team Stack Templates</div>
    <div class=top>
      <div class='text intro'>
        Team Stack Templates are shared among the members.
        Admins can edit and update, members can build them.
        If you update them users will be notified of the changes.
      </div>
      {{> @createStackButton }}
    </div>
    {{> @stackTemplateList}}
  """
