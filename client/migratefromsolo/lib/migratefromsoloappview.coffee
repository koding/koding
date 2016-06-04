kd = require 'kd'
getGroup = require 'app/util/getGroup'
ProvidersView = require 'stacks/views/stacks/providersview'
SoloMachinesListView = require './solomachineslistview'
EnvironmentFlux = require 'app/flux/environment'
MigrationFinishedView = require './migrationfinishedview'


module.exports = class MigrateFromSoloAppView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass or= kd.utils.curry 'MigrateFromSoloAppView', options.cssClass
    options.width ?= 800
    options.height ?= 600
    options.overlay ?= yes

    super options, data

    @credential = @machines = null

    @providersView = new ProvidersView { provider: 'aws' }
    @soloMachinesList = new SoloMachinesListView
    @progressBar = new kd.ProgressBarView { initial: 1 }

    @addSubView @providersView
    @addSubView @soloMachinesList
    @addSubView @progressBar

    @providersView.on 'ItemSelected', (credentialItem) =>
      @credential = credentialItem.getData()
      @switchToMachinesList()

    @soloMachinesList.on 'MachinesConfirmed', (machines) =>
      @machines = machines
      @switchToMigrationProcess()

    @switchToCredentials()


  switchToCredentials: ->

    @providersView.show()
    @soloMachinesList.hide()
    @progressBar.hide()


  switchToMachinesList: ->

    @providersView.hide()
    @soloMachinesList.show()
    @progressBar.hide()


  switchToMigrationProcess: ->

    { computeController } = kd.singletons
    { slug } = getGroup()

    @providersView.hide()
    @soloMachinesList.show()
    @progressBar.show()

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

    @destroySubViews()

    @addSubView view = new MigrationFinishedView

    view.on 'GoToStacksRequested', =>
      kd.singletons.router.handleRoute '/Home/Stacks'
      @destroy()


