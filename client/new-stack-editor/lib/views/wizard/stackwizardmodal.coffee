kd = require 'kd'

Events = require '../../events'
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

    wizard.once Events.ProviderSelected, (selectedProvider) =>
      kd.singletons.appManager
        .tell 'Stackeditor', 'createStackTemplate', selectedProvider
      @destroy()

    wizard.on Events.StackWizardCancelled, @bound 'destroy'

    if @getOption 'handleRoute'
      @on 'KDObjectWillBeDestroyed', -> kd.singletons.router.back()

    @addSubView wizard
