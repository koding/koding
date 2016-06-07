kd = require 'kd'
ReadmePageView = require '../views/readmepageview'
StackTemplatePageView = require '../views/stacktemplatepageview'
showError = require 'app/util/showError'

module.exports = class InstructionsController extends kd.Controller

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    { container } = @getOptions()
    stackTemplate = @getData()

    @readmePage = new ReadmePageView {}, stackTemplate
    @stackTemplatePage = new StackTemplatePageView {}, stackTemplate

    @forwardEvent @readmePage, 'NextPageRequested'
    @readmePage.on 'StackTemplateRequested', => container.showPage @stackTemplatePage
    @forwardEvent @stackTemplatePage, 'NextPageRequested'
    @stackTemplatePage.on 'ReadmeRequested', => container.showPage @readmePage

    container.appendPages @readmePage, @stackTemplatePage

    @emit 'ready'


  show: ->

    { container } = @getOptions()
    container.showPage @readmePage
