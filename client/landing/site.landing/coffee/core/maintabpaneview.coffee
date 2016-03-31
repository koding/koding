kd = require 'kd'
module.exports = class MainTabPane extends kd.TabPaneView

  constructor: (options, data) ->

    @id        or= options.id
    options.type = options.behavior

    super options, data

  show: ->

    super

    kd.utils.defer => window.scrollTo 0, @lastScrollTops.window


  hide: ->

    return  unless @active

    @lastScrollTops.window = window.scrollY

    super
