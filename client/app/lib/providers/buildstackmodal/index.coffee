kd = require 'kd'
async = require 'async'
BuildStackModalController = require './buildstackmodalcontroller'
ReadmePageView = require './readmepageview'
StackTemplatePageView = require './stacktemplatepageview'
CredentialsPageView = require './credentialspageview'
showError = require 'app/util/showError'

module.exports = class BuildStackModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'build-stack-modal', options.cssClass
    super options, data

    stack = @getData()
    @controller = new BuildStackModalController {}, stack

    @createInstructionsPages()
    @createCredentialsPage()


  createInstructionsPages: ->

    @controller.loadStackTemplate (err, stackTemplate) =>
      return showError err  if err

      @addSubView @readmePage = new ReadmePageView {}, stackTemplate
      @readmePage.on 'CredentialsPageRequested', =>
        helper.changePage @readmePage, @credentialsPage
      @readmePage.on 'StackTemplatePageRequested', =>
        helper.changePage @readmePage, @stackTemplatePage

      @addSubView @stackTemplatePage =
        new StackTemplatePageView { cssClass : 'hidden' }, stackTemplate
      @stackTemplatePage.on 'CredentialsPageRequested', =>
        helper.changePage @stackTemplatePage, @credentialsPage
      @stackTemplatePage.on 'ReadmePageRequested', =>
        helper.changePage @stackTemplatePage, @readmePage


  createCredentialsPage: ->

    stack = @getData()
    queue = [
      (next) =>
        @controller.loadCredentials next
      (next) =>
        @controller.loadRequirements next
    ]

    async.parallel queue, (err, results) =>
      return showError err  if err

      @addSubView @credentialsPage = new CredentialsPageView { cssClass : 'hidden' }, {
        stack
        credentials  : results[0]
        requirements : results[1]
      }


  helper =

    changePage: (currentPage, nextPage) ->

      currentPage.hide()
      nextPage.show()

