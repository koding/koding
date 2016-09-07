AdminAppView                = require 'admin/views/customviews/adminappview'
StackCatalogMainTabPaneView = require './stackcatalogmaintabpaneview'


module.exports = class StackCatalogModalView extends AdminAppView


  constructor: (options = {}, data) ->

    options.paneViewClass or= StackCatalogMainTabPaneView
    options.checkRoles     ?= no

    super options, data

    @overlay.on 'click', @bound 'handleOverlayClick'


  handleOverlayClick: ->

    activePane = @tabs.getActivePane()

    return @destroy()  if activePane.name is 'Your Stacks'

    { mainView } = activePane

    unless mainView?.defineStackView?.isStackChanged()
      @destroy()
