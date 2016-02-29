kd              = require 'kd'
JView           = require 'app/jview'
KDView          = kd.View
globals         = require 'globals'
KDListItemView  = kd.ListItemView


module.exports = class GroupPlanItemView extends KDListItemView

  JView.mixin @prototype


  constructor: (options = {}, data) ->

    super options, data

    { currentGroup }  = globals
    isCurrent         = currentGroup.config?.plan is data.name
    text              = if isCurrent then 'current' else 'upgrade'

    @button = new KDView
      partial   : text
      cssClass  : text
      click     : ->
        return  if isCurrent


  pistachio: ->

    plan = @getData()

    return """
      <div class='plan-name'>#{plan.name}</div>
      <div class='plan-info'>
        <strong>max #{plan.member} member(s)</strong>
        <i>Limited to #{plan.maxInstance} instance(s)</i>
      </div>
      <div class='button'>{{> @button}}</div>
    """
