kd = require 'kd'
async = require 'async'
BuildStackModalController = require './buildstackmodalcontroller'
ReadmePageView = require './readmepageview'
CredentialsPageView = require './credentialspageview'
showError = require 'app/util/showError'

module.exports = class BuildStackModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'build-stack-modal', options.cssClass
    super options, data

    stack = @getData()
    @controller = new BuildStackModalController {}, stack

    @createReadmePage()
    @createCredentialsPage()


  createReadmePage: ->

    @controller.loadStackTemplate (err, stackTemplate) =>
      return showError err  if err

      @addSubView @readmePage = new ReadmePageView {}, stackTemplate
      @readmePage.on 'CredentialsPageRequested', =>
        helper.changePage @readmePage, @credentialsPage


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

