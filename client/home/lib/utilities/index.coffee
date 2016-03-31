kd                      = require 'kd'
HomeUtilitiesKD         = require './homeutilitieskd'
HomeUtilitiesDesktopApp = require './homeutilitiesdesktopapp'


SECTIONS =
  'KD CLI'          : HomeUtilitiesKD
  'Koding OS X App' : HomeUtilitiesDesktopApp

header = (title) ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title

section = (name) ->
  new (SECTIONS[name] or kd.View)
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"


module.exports = class HomeUtilities extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView header  'KD CLI'
    @wrapper.addSubView section 'KD CLI'

    @wrapper.addSubView header  'Koding OS X App'
    @wrapper.addSubView section 'Koding OS X App'
