kd = require 'kd'
getGroup = require 'app/util/getGroup'
ProvidersView = require 'stacks/views/stacks/providersview'
SoloMachinesListView = require './solomachineslistview'
EnvironmentFlux = require 'app/flux/environment'
MigrationFinishedView = require './migrationfinishedview'


module.exports = class MigrateFromSoloAppView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'BaseModalView MigrateFromSoloAppView', options.cssClass
    options.width = 800
    options.height = 700
    options.overlay ?= yes

    super options, data

    @machines = null
    @credential = null

    @mainHeader = new kd.CustomHTMLView
      tagName: 'header'
      partial: '<h1>Import VMs From Koding Solo</h1>'
      cssClass: 'mainHeader'

    @mainSection = new kd.CustomHTMLView
      tagName: 'section'
      cssClass: 'main mainSection'

    @mainSection.addSubView @stepHeader = new kd.CustomHTMLView
      tagName: 'h2'
      cssClass: 'stepHeader'

    @mainSection.addSubView @stepDescription = new kd.CustomHTMLView
      tagName: 'p'
      cssClass: 'stepDescription'

    @mainSection.addSubView @stepContainer = new kd.CustomHTMLView
      tagName: 'div'
      cssClass: 'stepContainer'

    @stepContainer.addSubView @providersView = new ProvidersView { provider: 'aws' }
    @stepContainer.addSubView @soloMachinesList = new SoloMachinesListView
    @stepContainer.addSubView @progressBar = new kd.ProgressBarView { initial: 1 }
    @stepContainer.addSubView @statusText = new kd.CustomHTMLView { cssClass: 'status-text' }

    @providersView.on 'ItemSelected', (credentialItem) =>
      @credential = credentialItem.getData()
      @switchToMachinesList()

    @soloMachinesList.on 'MachinesConfirmed', (machines) =>
      @machines = machines
      @switchToMigrationProcess()

    @mainFooter = new kd.CustomHTMLView
      tagName: 'footer'
      cssClass: 'mainFooter'

    @mainFooter.addSubView @backLink = new kd.CustomHTMLView
      tagName: 'a'
      partial: 'GO BACK'
      cssClass: 'back-link'
      attributes: { href: '#' }

    @mainFooter.addSubView @nextButton = new kd.ButtonView
      title    : 'Next'
      cssClass : 'GenericButton'

    @addSubView @mainHeader
    @addSubView @mainSection
    @addSubView @mainFooter

    @switchToCredentials()

    @on 'KDObjectWillBeDestroyed', ->
      kd.singletons.router.handleRoute '/IDE'


  setBackLinkCallback: (cb) ->

    @backLink.off 'click'
    @backLink.on 'click', (event) ->
      kd.utils.stopDOMEvent event
      cb()


  switchToCredentials: ->

    @stepHeader.updatePartial 'Select Personal AWS Credentials'
    @stepDescription.updatePartial 'Your personal AWS credentials are required to import your solo account.'

    @setBackLinkCallback kd.noop
    @backLink.hide()
    @nextButton.hide()

    @providersView.show()
    @soloMachinesList.hide()
    @progressBar.hide()
    @statusText.hide()


  switchToMachinesList: ->

    @stepHeader.updatePartial 'Select the VMs You Would Like to Transfer'
    @stepDescription.updatePartial 'A new stack will be created in Koding Teams for the selected VMs.'

    @setBackLinkCallback @bound 'switchToCredentials'

    @backLink.show()
    @nextButton.hide()

    @providersView.hide()
    @soloMachinesList.show()
    @progressBar.hide()
    @statusText.hide()


  switchToMigrationProcess: ->

    { computeController } = kd.singletons
    { slug } = getGroup()

    @stepHeader.updatePartial 'A New Stack is Being Created for Your VMs'
    @stepDescription.updatePartial 'Once your VM’s are transferred they will be located under the stacks menu in a new stack called “Migrated Stack Template”.'

    @setBackLinkCallback @bound 'switchToCredentials'

    @statusText.updatePartial 'Migration in progress...'

    @providersView.hide()
    @soloMachinesList.hide()
    @progressBar.show()
    @statusText.show()

    computeController.getKloud().migrate(
      provider: 'aws'
      groupName: slug
      machines: @machines
      identifier: @credential.identifier
    ).then ({ eventId }) =>

      eventName = "migrate-#{slug}"

      splitted = eventId.split '-'
      computeController.eventListener.addListener eventName, splitted.last

      handler = ({ percentage }) =>
        @progressBar.updateBar percentage

        if percentage >= 100
          computeController.off eventName, handler
          EnvironmentFlux.actions.loadPrivateStackTemplates().then =>
            # TODO: right now the migrated stacks' access level is group,
            # so load the team stack templates. Remove this after access level
            # is correct (private)
            EnvironmentFlux.actions.loadTeamStackTemplates().then =>
              kd.utils.wait 500, @bound 'switchToFinishedView'

      computeController.on eventName, handler

    .catch kd.warn


  switchToFinishedView: ->

    @mainSection.destroySubViews()

    @mainSection.addSubView view = new MigrationFinishedView

    @backLink.hide()

    @nextButton.setTitle 'Start Koding'
    @nextButton.setCallback =>
      kd.singletons.router.handleRoute '/Home/Stacks'
      @destroy()

    @nextButton.show()


