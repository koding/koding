kd = require 'kd'
EnvironmentFlux = require 'app/flux/environment'

StackWizard = require './stackwizard'


module.exports = class StackWizardModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options          =
      handleRoute    : options.handleRoute ? no
      cssClass       : 'stack-wizard-modal'
      width          : 820
      overlay        : yes
      overlayOptions :
        cssClass     : 'second-overlay'

    super options, data

    wizard = new StackWizard

    wizard.once 'ProviderSelected', (selectedProvider) =>
      @createStackTemplate selectedProvider
      @destroy()

    wizard.on 'StackWizardCancelled', @bound 'destroy'

    if @getOption 'handleRoute'
      @on 'KDObjectWillBeDestroyed', -> kd.singletons.router.back()

    @addSubView wizard


  createStackTemplate: (selectedProvider) ->

    { router } = kd.singletons

    unless selectedProvider
      return router.handleRoute '/IDE'

    EnvironmentFlux.actions.createStackTemplateWithDefaults selectedProvider
      .then ({ stackTemplate }) ->
        router.handleRoute "/Stack-Editor/#{stackTemplate._id}"
