kd               = require 'kd'
HomeStacksCreate = require './homestackscreate'


module.exports = class HomeStacks extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data


  viewAppended: ->

    super

    @wrapper.addSubView new HomeStacksCreate
