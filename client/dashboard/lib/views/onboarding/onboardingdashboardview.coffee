kd = require 'kd'
KDButtonView = kd.ButtonView
CustomViewsDashboardView = require '../customviews/customviewsdashboardview'
OnboardingAddNewForm = require './onboardingaddnewform'
OnboardingSectionForm = require './onboardingsectionform'
OnboardingGroupView = require './onboardinggroupview'


module.exports = class OnboardingDashboardView extends CustomViewsDashboardView

  constructor: (options = {}, data) ->

    options.cssClass = "onboarding-view custom-views"
    options.viewType = "ONBOARDING"

    super options, data

    @addNewButton  = new KDButtonView
      title        : "ADD NEW GROUP"
      cssClass     : "add-new solid green medium"
      callback     : =>
        @setClass  "form-visible"
        @addSubView new OnboardingSectionForm
          delegate : this

    @on "SectionSaved", =>
      @unsetClass "form-visible"
      @container.destroySubViews()
      @reloadViews()
    @on "SectionCancelled", =>
      @unsetClass "form-visible"


  createList: (sections) ->

    @noViewLabel.hide()
    for section in sections
      view = new OnboardingGroupView
        delegate    : this
        title       : section.name
        cssClass    : "onboarding-items"
        formClass   : OnboardingAddNewForm
      , section

      @customViews.push view
      @container.addSubView view


