kd              = require 'kd'
KDTabHandleView = kd.TabHandleView


module.exports = class BranchTabHandleView extends KDTabHandleView

  constructor: (options = {}, data) ->

    options.closable    or= no
    options.closeHandle  ?= null

    super options, data


  partial: ->

    { pane, title } = @getOptions()

    """
      <a href="/Pricing/#{pane.getOption('subPath')}" title="#{title}">#{title}</a>
    """
