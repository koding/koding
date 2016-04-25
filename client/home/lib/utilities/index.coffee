kd                            = require 'kd'
sectionize                    = require '../commons/sectionize'
headerize                     = require '../commons/headerize'
HomeUtilitiesKD               = require './homeutilitieskd'
HomeUtilitiesTryOnKoding      = require './homeutilitiestryonkoding'
#HomeUtilitiesDesktopApp       = require './homeutilitiesdesktopapp'
HomeUtilitiesCustomerFeedback = require './homeutilitiescustomerfeedback'
TeamFlux                      = require 'app/flux/teams'


module.exports = class HomeUtilities extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data
    
    TeamFlux.actions.loadTeam() 
    
    @wrapper.addSubView headerize  'KD CLI'
    @wrapper.addSubView sectionize 'KD CLI', HomeUtilitiesKD

    #@wrapper.addSubView headerize  'Koding OS X App'
    #@wrapper.addSubView sectionize 'Koding OS X App', HomeUtilitiesDesktopApp

    @wrapper.addSubView headerize  'Koding Button'
    @wrapper.addSubView sectionize 'Koding Button', HomeUtilitiesTryOnKoding

    @wrapper.addSubView headerize  'Integrations'

    @wrapper.addSubView sectionize 'Customer Feedback', HomeUtilitiesCustomerFeedback
