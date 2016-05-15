kd = require 'kd'
ReadmePageView = require '../views/readmepageview'
StackTemplatePageView = require '../views/stacktemplatepageview'
helpers = require '../helpers'
showError = require 'app/util/showError'

module.exports = class InstructionsController extends kd.Controller

  constructor: (options, data) ->

    super options, data
    @loadData()


  loadData: ->

    stack = @getData()
    { computeController } = kd.singletons

    computeController.fetchBaseStackTemplate stack, @bound 'onDataLoaded'


  onDataLoaded: (err, stackTemplate) ->

    return showError err  if err

    @delegate.addSubView @readmePage = new ReadmePageView {}, stackTemplate
    @forwardEvent @readmePage, 'NextPageRequested'
    @readmePage.on 'StackTemplateRequested', =>
      helpers.changePage @readmePage, @stackTemplatePage

    @delegate.addSubView @stackTemplatePage =
      new StackTemplatePageView { cssClass : 'hidden' }, stackTemplate
    @forwardEvent @stackTemplatePage, 'NextPageRequested'
    @stackTemplatePage.on 'ReadmeRequested', =>
      helpers.changePage @stackTemplatePage, @readmePage


  show: ->

    @readmePage.show()


  hide: ->

    @readmePage.hide()
    @stackTemplatePage.hide()
