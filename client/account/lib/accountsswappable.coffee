kd = require 'kd'
KDView = kd.View
$ = require 'jquery'

module.exports = class AccountsSwappable extends KDView
  constructor:(options,data)->
    options = $.extend
      views : []          # an Array of two KDView instances
    ,options
    super
    @setClass "swappable"
    @addSubView(@view1 = @options.views[0]).hide()
    @addSubView @view2 = @options.views[1]

  swapViews:->
    if @view1.$().is(":visible")
      @view1.hide()
      @view2.show()
    else
      @view1.show()
      @view2.hide()
