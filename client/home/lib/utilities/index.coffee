kd                                     = require 'kd'
sectionize                             = require '../commons/sectionize'
headerize                              = require '../commons/headerize'
HomeUtilitiesKD                        = require './homeutilitieskd'
HomeUtilitiesTryOnKoding               = require './homeutilitiestryonkoding'
HomeUtilitiesTryOnKodingSecondary      = require './homeutilitiestryonkodingsecondary'
HomeUtilitiesDesktopApp                = require './homeutilitiesdesktopapp'

module.exports = class HomeUtilities extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView headerize  'KD CLI'
    @wrapper.addSubView sectionize 'KD CLI', HomeUtilitiesKD

    @wrapper.addSubView headerize  'Koding OS X App'
    @wrapper.addSubView sectionize 'Koding OS X App', HomeUtilitiesDesktopApp

    @wrapper.addSubView headerize  'Koding Button'

    tryOn          = sectionize 'Koding Button', HomeUtilitiesTryOnKoding
    tryOnSecondary = sectionize 'Koding Button Secondary', HomeUtilitiesTryOnKodingSecondary, { cssClass: 'hidden' }

    @wrapper.addSubView tryOn
    @wrapper.addSubView tryOnSecondary


    tryOn.on 'TryOnKodingActivated', =>
      tryOnSecondary.show()
      @wrapper.scrollToBottom 177
    tryOn.on 'TryOnKodingDeactivated', -> tryOnSecondary.hide()

