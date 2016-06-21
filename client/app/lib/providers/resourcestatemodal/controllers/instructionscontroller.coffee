kd = require 'kd'
ReadmePageView = require '../views/stackflow/readmepageview'
StackTemplatePageView = require '../views/stackflow/stacktemplatepageview'
showError = require 'app/util/showError'

module.exports = class InstructionsController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    { container } = @getOptions()
    stackTemplate = @getData()

    @readmePage = new ReadmePageView {}, stackTemplate
    @stackTemplatePage = new StackTemplatePageView {}, stackTemplate

    @forwardEvent @readmePage, 'NextPageRequested'
    @readmePage.on 'StackTemplateRequested', => container.showPage @stackTemplatePage
    @forwardEvent @stackTemplatePage, 'NextPageRequested'
    @stackTemplatePage.on 'ReadmeRequested', => container.showPage @readmePage

    container.appendPages @readmePage, @stackTemplatePage


  show: ->

    { container } = @getOptions()
    container.showPage @readmePage
