kd = require 'kd'
KDButtonView = kd.ButtonView
CustomViewsDashboardView = require '../customviews/customviewsdashboardview'
OnboardingAddNewForm = require './onboardingaddnewform'
OnboardingSectionForm = require './onboardingsectionform'
OnboardingGroupView = require './onboardinggroupview'
OnboardingChildItem = require 'dashboard/onboardingchilditem'


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
        sectionForm = new OnboardingSectionForm()
        @bindFormEvents sectionForm
        @addSubView sectionForm


  createList: (sections) ->

    @noViewLabel.hide()
    for section in sections
      view = new OnboardingGroupView
        delegate    : this
        title       : section.name
        cssClass    : "onboarding-items"
        formClass   : OnboardingAddNewForm
        itemClass   : OnboardingChildItem
      , section
      @bindFormEvents view

      @customViews.push view
      @container.addSubView view


  bindFormEvents: (formView) ->

    formView.on 'SectionSaved',     @bound 'handleSectionSaved'
    formView.on 'SectionCancelled', @bound 'handleSectionCancelled'


  handleSectionSaved: ->

    @unsetClass 'form-visible'
    @container.destroySubViews()
    @reloadViews()


  handleSectionCancelled: -> @unsetClass 'form-visible'