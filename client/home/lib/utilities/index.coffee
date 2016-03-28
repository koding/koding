kd                      = require 'kd'
HomeUtilitiesKD         = require './homeutilitieskd'
HomeUtilitiesDesktopApp = require './homeutilitiesdesktopapp'


SECTIONS =
  'KD CLI'          : HomeUtilitiesKD
  'Koding OS X App' : HomeUtilitiesDesktopApp

section = (name) ->
  new (SECTIONS[name] or kd.View)
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"


module.exports = class HomeUtilities extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    @addSubView scrollView = new kd.CustomScrollView
      cssClass : 'HomeAppView--scroller'

    { wrapper } = scrollView

    wrapper.addSubView section 'KD CLI'
    wrapper.addSubView section 'Koding OS X App'
