kd                               = require 'kd'
os                               = require 'os'
sectionize                       = require '../commons/sectionize'
headerize                        = require '../commons/headerize'
HomeUtilitiesKD                  = require './homeutilitieskd'
HomeUtilitiesTryOnKoding         = require './homeutilitiestryonkoding'
HomeUtilitiesDesktopApp          = require './homeutilitiesdesktopapp'
HomeUtilitiesCustomerFeedback    = require './homeutilitiescustomerfeedback'
HomeUtilitiesIntercomIntegration = require './homeutilitiesintercomintegration'
TeamFlux                         = require 'app/flux/teams'


module.exports = class HomeUtilities extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    TeamFlux.actions.loadTeam()
    team = kd.singletons.groupsController.getCurrentGroup()
    canEdit = kd.singletons.groupsController.canEditGroup()
    allowedDomains = team.allowedDomains

    @wrapper.addSubView headerize  'KD CLI'
    @wrapper.addSubView sectionize 'KD CLI', HomeUtilitiesKD

    switch os
      when 'mac'
        @wrapper.addSubView headerize  'Koding OS X App'
        @wrapper.addSubView sectionize 'Koding App', HomeUtilitiesDesktopApp
      when 'linux'
        @wrapper.addSubView headerize  'Koding Linux App'
        @wrapper.addSubView sectionize 'Koding App', HomeUtilitiesDesktopApp

    if '*' in allowedDomains or canEdit
        @wrapper.addSubView headerize  'Koding Button'
        @wrapper.addSubView sectionize 'Koding Button', HomeUtilitiesTryOnKoding

    if canEdit
        @wrapper.addSubView headerize  'Integrations'
        @wrapper.addSubView sectionize 'Customer Feedback', HomeUtilitiesCustomerFeedback
        @wrapper.addSubView sectionize 'Intercom Integration', HomeUtilitiesIntercomIntegration
