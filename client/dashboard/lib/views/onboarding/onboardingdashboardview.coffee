kd = require 'kd'
KDButtonView = kd.ButtonView
CustomViewsDashboardView = require '../customviews/customviewsdashboardview'
OnboardingAddNewForm = require './onboardingaddnewform'
OnboardingSectionForm = require './onboardingsectionform'
OnboardingGroupView = require './onboardinggroupview'
OnboardingChildItem = require 'dashboard/onboardingchilditem'


module.exports = class OnboardingDashboardView extends CustomViewsDashboardView

  ###*
   * View that renders a list of onboarding group views
   * and manages them
  ###
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


  ###*
   * Creates a list of onboarding group views
   * and binds to their events
   *
   * @param {Array} sections - a list of onboarding groups
  ###
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


  ###*
   * Binds to onboarding group view events
   *
   * @param {object} formView - if onboarding group is new,
   * then formView is instance of OnboardingSectionForm. Otherwise,
   * it's instance of OnboardingGroupView
  ###
  bindFormEvents: (formView) ->

    formView.on 'SectionSaved',     @bound 'handleSectionSaved'
    formView.on 'SectionCancelled', @bound 'handleSectionCancelled'


  ###*
   * When onboarding group is saved,
   * it's necessary to refresh a list of onboarding groups
   * and hide a form for a new onboarding group
  ###
  handleSectionSaved: ->

    @unsetClass 'form-visible'
    @container.destroySubViews()
    @reloadViews()


  ###*
   * When onboarding group is cancelled,
   * hide a form for a new onboarding group
   * and show a list of onboarding groups
  ###
  handleSectionCancelled: -> @unsetClass 'form-visible'