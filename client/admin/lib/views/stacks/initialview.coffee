kd    = require 'kd'
JView = require 'app/jview'

StackTemplateListView = require './stacktemplatelistview'

module.exports = class InitialView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'stacktemplates'

    super options, data

    @createStackButton = new kd.ButtonView
      title    : 'Create new Stack'
      cssClass : 'solid compact green action'
      callback : => @emit 'CreateNewStack'

    @stackTemplateList = new StackTemplateListView

    @stackTemplateList.listView.on 'ItemSelected', (stackTemplate) =>
      @emit 'EditStack', stackTemplate

    @stackTemplateList.listController.on 'ItemsLoaded', (stackTemplates) =>
      @emit 'NoTemplatesFound'  if stackTemplates.length is 0


  reload: ->
    @stackTemplateList.listController.loadItems()


  pistachio: ->
    """
      <div class='text header'>Compute Stack Templates</div>
      <div class=top>
        <div class='text intro'>
          Stack Templates are awesome because when a user
          joins your group you can preconfigure their work
          environment by defining stacks.
          Learn more about stacks
        </div>
        {{> @createStackButton}}
      </div>
      {{> @stackTemplateList}}
    """
