kd                 = require 'kd'
KDViewController   = kd.ViewController
WelcomeAppView     = require './welcomeappview'
collectCredentials = require 'app/util/collectCredentials'

module.exports = class WelcomeAppController extends KDViewController

  @options =
    name  : 'Welcome'
    route : '/Welcome'

  constructor:(options = {}, data)->

    options.view    = new WelcomeAppView
      cssClass      : 'content-page welcome'

    super options, data


  loadView: (appView) ->

    { groupsController, computeController } = kd.singletons

    groupsController.ready -> computeController.ready ->

      { providers, variables } = collectCredentials()

      groupsController.getCurrentGroup().fetchMyRoles (err, roles) ->
        return  kd.warn err  if err
        isAdmin = 'admin' in (roles ? [])

        console.log { isAdmin, providers, variables }

        if isAdmin
          appView.putAdminInstructions()

        # if stacks
        #   appView.putCredentialInstructions()
