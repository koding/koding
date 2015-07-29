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
      callback : -> alert 'FIX ME'

    @stackTemplateList = (new StackTemplateListView)
      .listView.on 'ItemSelected', (stackTemplate) ->
        console.log 'Selected Template:', stackTemplate


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
