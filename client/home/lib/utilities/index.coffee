kd                                     = require 'kd'
sectionize                             = require '../commons/sectionize'
headerize                              = require '../commons/headerize'
HomeUtilitiesKD                        = require './homeutilitieskd'
HomeUtilitiesDesktopApp                = require './homeutilitiesdesktopapp'

module.exports = class HomeUtilities extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView headerize  'KD CLI'
    @wrapper.addSubView sectionize 'KD CLI', HomeUtilitiesKD

    @wrapper.addSubView headerize  'Koding OS X App'
    @wrapper.addSubView sectionize 'Koding OS X App', HomeUtilitiesDesktopApp





