kd = require 'kd'
KDContextMenu = kd.ContextMenu
module.exports = class OnboardingContextMenu extends KDContextMenu

  childAppended: ->
    kd.utils.defer => @positionContextMenu()

