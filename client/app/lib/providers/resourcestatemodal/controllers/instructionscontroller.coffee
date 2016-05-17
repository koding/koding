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

    computeController.fetchBaseStackTemplate stack, (err, stackTemplate) =>
      return showError err  if err

      @createPages stackTemplate
      @emit 'ready'


  createPages: (stackTemplate) ->

    { container } = @getOptions()

    container.addSubView @readmePage = new ReadmePageView {}, stackTemplate
    @readmePage.hide()
    @forwardEvent @readmePage, 'NextPageRequested'
    @readmePage.on 'StackTemplateRequested', =>
      helpers.changePage @readmePage, @stackTemplatePage

    container.addSubView @stackTemplatePage = new StackTemplatePageView {}, stackTemplate
    @stackTemplatePage.hide()
    @forwardEvent @stackTemplatePage, 'NextPageRequested'
    @stackTemplatePage.on 'ReadmeRequested', =>
      helpers.changePage @stackTemplatePage, @readmePage


  show: ->

    @ready => @readmePage.show()


  hide: ->

    @readmePage.hide()
    @stackTemplatePage.hide()
