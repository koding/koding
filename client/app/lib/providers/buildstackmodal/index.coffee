kd = require 'kd'
_  = require 'lodash'
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
      @readmePage.on 'NextPageRequested', =>
        helper.changePage @readmePage, @credentialsPage
      @readmePage.on 'StackTemplateRequested', =>
        helper.changePage @readmePage, @stackTemplatePage

      @addSubView @stackTemplatePage =
        new StackTemplatePageView { cssClass : 'hidden' }, stackTemplate
      @stackTemplatePage.on 'NextPageRequested', =>
        helper.changePage @stackTemplatePage, @credentialsPage
      @stackTemplatePage.on 'ReadmeRequested', =>
        helper.changePage @stackTemplatePage, @readmePage


  createCredentialsPage: ->

    stack = @getData()
    queue = {
      credentials  : (next) => @controller.loadCredentials next
      requirements : (next) => @controller.loadRequirements next
      kdCmd        : (next) => @controller.getKDCmd next
    }

    async.parallel queue, (err, results) =>
      return showError err  if err

      { credentials, requirements, kdCmd } = results
      @addSubView @credentialsPage = new CredentialsPageView { cssClass : 'hidden' }, {
        stack
        credentials  : _.extend { kdCmd }, credentials
        requirements
      }
      @credentialsPage.on 'InstructionsRequested', =>
        helper.changePage @credentialsPage, @readmePage


  helper =

    changePage: (currentPage, nextPage) ->

      currentPage.hide()
      nextPage.show()

