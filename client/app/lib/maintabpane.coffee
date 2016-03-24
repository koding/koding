kd = require 'kd'
KDTabPaneView = kd.TabPaneView
module.exports = class MainTabPane extends KDTabPaneView

  constructor: (options, data) ->

    @id        or= options.id
    options.type = options.behavior

    super options, data

  show: ->

    super

    kd.utils.defer => global.scrollTo 0, @lastScrollTops.window


  hide: ->

    return  unless @active

    @lastScrollTops.window = global.scrollY

    super
