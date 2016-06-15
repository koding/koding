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

  constructor: (options = {}, data) ->

    super options, data

    # a cache to register created views.
    @editors = {}


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
        @showView stackTemplate
    else
      @showView()


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


  showView: (stackTemplate) ->

    stackTemplate or= { _id: 'default' }

    id = stackTemplate._id

    unless @editors[id]
      @editors[id] = editor = @createEditor stackTemplate
      editor.on 'Reload', @lazyBound 'reloadEditor', stackTemplate
      @mainView.addSubView editor

    return  unless editor = @editors[id]

    # hide all editors
    Object.keys(@editors).forEach (templateId) =>
      view = @editors[templateId]

      view.getElement().removeAttribute 'testpath'
      view.hide()

    # show the correct editor.
    editor.setAttribute 'testpath', 'StackEditor-isVisible'
    editor.show()


  reloadEditor: (template) ->

    editor = @editors[template._id]
    delete @editors[template._id]

    editor.destroy()

    @showView template


  createEditor: (stackTemplate) ->

    template = if stackTemplate._id is 'default' then null else stackTemplate

    options = { cssClass: 'hidden', skipFullscreen: yes }
    data    = { stackTemplate: template, showHelpContent: not stackTemplate }

    view    = new StackEditorView options, data
    view.on 'Cancel', -> kd.singletons.router.back()

    # TODO: Will activate this with following PRs.
    # Not removing to leave it as ref. ~Umut
    # confirmation = null

    # stackTemplate.on? 'update', =>

    #   return  if confirmation

    #   view.addSubView confirmation = new kd.ModalView
    #     title: 'Stack Template is Updated'
    #     buttons:
    #       ok:
    #         title: 'OK'
    #         style: 'solid green medium'
    #         callback: =>
    #           view.destroy()
    #           delete @editors[stackTemplate._id]
    #           @openEditor stackTemplate._id
    #       cancel:
    #         title: 'Cancel'
    #         style: 'solid light-gray medium'
    #         callback: ->
    #           confirmation.destroy()
    #           confirmation = null
    #     content: '''
    #       <div class='modalformline'
    #         <p>This stack template is updated by another admin. Do you want to reload?
    #       </div>
    #       '''

    return view


