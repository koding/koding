kd = require 'kd'
BasePageController = require './basepagecontroller'
ReadmePageView = require '../views/readmepageview'
StackTemplatePageView = require '../views/stacktemplatepageview'
showError = require 'app/util/showError'

module.exports = class InstructionsController extends BasePageController

  constructor: (options, data) ->

    super options, data
    @loadData()


  loadData: ->

    stack = @getData()
    { computeController } = kd.singletons

    computeController.fetchBaseStackTemplate stack, (err, stackTemplate) =>
      return showError err  if err

      @createPages stackTemplate


  createPages: (stackTemplate) ->

    @readmePage = new ReadmePageView {}, stackTemplate
    @stackTemplatePage = new StackTemplatePageView {}, stackTemplate

    @forwardEvent @readmePage, 'NextPageRequested'
    @readmePage.on 'StackTemplateRequested', @lazyBound 'setCurrentPage', @stackTemplatePage
    @forwardEvent @stackTemplatePage, 'NextPageRequested'
    @stackTemplatePage.on 'ReadmeRequested',  @lazyBound 'setCurrentPage', @readmePage

    @registerPages [ @readmePage, @stackTemplatePage ]
