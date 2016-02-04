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
    <div class='text header'>Compute Stack Templates</div>
    <div class=top>
      <div class='text intro'>
        Stack Templates are awesome because when a user
        joins your group you can preconfigure their work
        environment by defining stacks.
        Learn more about stacks
      </div>
      {{> @createStackButton }}
    </div>
    {{> @stackTemplateList}}
  """
