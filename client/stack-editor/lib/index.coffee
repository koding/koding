_ = require 'lodash'
kd = require 'kd'
AppController = require 'app/appcontroller'
StackEditorView = require './editor'
showError = require 'app/util/showError'
OnboardingView = require 'stacks/views/stacks/onboarding/onboardingview'
EnvironmentFlux = require 'app/flux/environment'

do require './routehandler'

module.exports = class StackEditorAppController extends AppController

  @options     =
    name       : 'Stackeditor'
    behavior   : 'application'


  openEditor: (stackTemplateId) ->

    { mainController } = kd.singletons
    mainController.tellChatlioWidget 'isShown', {}, (err, isShown) ->
      return if err
      return if isShown
      mainController.tellChatlioWidget 'show', { expanded: no }

    { computeController } = kd.singletons

    if stackTemplateId
      computeController.fetchStackTemplate stackTemplateId, (err, stackTemplate) =>
        return showError err  if err
        @createView stackTemplate
    else
      @createView()


  openStackWizard: ->

    @openEditor()

    modal = new kd.ModalView
      cssClass : 'StackEditor-OnboardingModal'
      width : 820
      overlay : yes

    view = new OnboardingView

    createOnce = do (isCreated = no) -> (overrides) ->
      return  if isCreated
      isCreated = yes

      { router } = kd.singletons

      return router.handleRoute '/IDE'  unless overrides

      EnvironmentFlux.actions.createStackTemplateWithDefaults overrides
        .then ({ stackTemplate }) ->
          router.handleRoute "/Stack-Editor/#{stackTemplate._id}"

    view.on 'StackOnboardingCompleted', (result) ->
      overrides = {}

      if result?.template
        overrides = _.assign overrides, { template: result.template.content }

      if result?.selectedProvider
        overrides = _.assign overrides, { selectedProvider: result.selectedProvider }

      createOnce overrides
      modal.destroy()

    modal.addSubView view

    modal.on 'KDObjectWillBeDestroyed', createOnce

    view.on 'StackCreationCancelled', ->
      modal.off 'KDObjectWillBeDestroyed'
      modal.destroy()
      createOnce()


  createView: (stackTemplate) ->

    options = { skipFullscreen: yes }
    data    = { stackTemplate, showHelpContent: not stackTemplate }

    @mainView.destroySubViews()

    view    = new StackEditorView options, data
    view.on 'Cancel', -> kd.singletons.router.back()

    @mainView.addSubView view
