actions = require '../actiontypes'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'

module.exports = class WelcomeStepsStore extends KodingFluxStore

  @getterPath = 'WelcomeStepsStore'


  getInitialState: ->

    toImmutable
      admin :
        stackCreation :
          path: '/Stack-Editor'
          title: 'Create a Stack for Your Team'
          description: "Create a blueprint for your team’s entire infrastructure."
          isDone: no
          order: 0
        buildStack :
          path: '/IDE'
          title: 'Build Your Stack'
          description: "You have a stack ready to go, go ahead and build it."
          isDone: no
          order: 1
      member :
        stackCreation :
          path: '/Stack-Editor'
          title: 'Create a Personal Stack'
          description: "While waiting for your team resources, you can experiment stacks."
          isDone: no
          order: 0
        pendingStack :
          path: '#'
          title: 'Your Team Stack is Pending'
          description: "Your team admins haven't created your stack yet."
          isDone: no
          order: 0
        buildStack :
          path: '/IDE'
          title: 'Build Your Stack'
          description: "Your team admins have already created your stack, it is ready for you to build."
          isDone: no
          order: 1
      common :
        inviteTeam :
          path: '/Home/My-Team'
          title: 'Invite Your Team'
          description: "Get your teammates working together."
          isDone: no
          order: 10
        installKd :
          path: '/Home/Koding-Utilities'
          title: 'Install KD'
          description: "<code>kd</code> is a CLI tool that allows you to use your local IDEs."
          isDone: no
          order: 20


  initialize: ->

    @on actions.MARK_WELCOME_STEP_AS_DONE, @handleMarkAsDone

    @on actions.MIGRATION_AVAILABLE, @handleMigration


  handleMarkAsDone: (steps, { step }) -> steps.setIn [ step, 'isDone' ], yes


  handleMigration: (steps) ->

    steps.setIn [ 'common', 'migrateFromKoding' ], toImmutable
      path: '/MigrateFromSolo'
      title: 'Migrate from Solo'
      description: "You can migrate your solo machines to team!"
      isDone: no
      order: 30
      starred: yes
