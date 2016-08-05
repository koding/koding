actions = require '../actiontypes'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'
__t = require('i18next').t

module.exports = class WelcomeStepsStore extends KodingFluxStore

  @getterPath = 'WelcomeStepsStore'


  getInitialState: ->

    toImmutable
      admin :
        stackCreation :
          path: '/Stack-Editor'
          title: __t 'Create a Stack for Your Team'
          actionTitle: __t 'Create'
          miniTitle: __t 'Create a Stack'
          description: __t "Create a blueprint for your team's entire infrastructure"
          isDone: no
          order: 1
          skippable: no
        enterCredentials :
          path: '/Stack-Editor'
          title: __t 'Enter your Credentials'
          actionTitle: __t 'Enter'
          videoLink: ''
          miniTitle: __t 'Enter Credentials'
          description: __t 'To set up your machines we need your cloud provider credentials.'
          isDone: no
          order: 2
          skippable: no
        buildStack :
          path: '/IDE'
          title: __t 'Build Your Stack'
          actionTitle: __t 'Build'
          videoLink: ''
          description: __t 'To access your VMs you need to build your stack.'
          isDone: no
          order: 3
          skippable: no
        inviteTeam :
          path: '/Home/My-Team/send-invites'
          title: __t 'Invite Your Team'
          actionTitle: 'Invite'
          videoLink: ''
          # videoLink: '//www.koding.com/docs'
          miniTitle: 'Invite Teammates'
          description: 'Get your teammates working together.'
          isDone: no
          order: 10
          skippable: yes
      member :
        pendingStack :
          path: '#'
          title: 'Your Team Stack is Pending'
          miniTitle: 'Stack Pending'
          actionTitle: 'Pending'
          videoLink: ''
          description: 'Your team admins haven\'t created your stack yet.'
          isDone: no
          isPending: yes
          order: 1
          skippable: no
        buildStack :
          path: '/IDE'
          title: 'Build Your Stack'
          actionTitle: 'Build'
          videoLink: ''
          description: 'To access your VMs you need to build your stack.'
          isDone: no
          order: 2
          skippable: no
        stackCreation :
          path: '/Stack-Editor'
          title: 'Create a Personal Stack'
          actionTitle: 'Create'
          videoLink: ''
          miniTitle: 'Create a Stack'
          description: 'While waiting for your team resources, you can experiment stacks.'
          isDone: no
          order: 3
          skippable: yes
      common :
        # watchVideo :
        #   path: '/Welcome/Intro'
        #   title: 'Watch Intro Video'
        #   actionTitle: 'Watch Intro Video'
        #   videoLink: ''
        #   description: "You are all set, watch our short video to know how to use Koding."
        #   isDone: no
        #   order: 0
        #   skippable: no
        installKd :
          path: '/Home/Koding-Utilities/kd-cli'
          title: 'Install KD'
          actionTitle: 'Install'
          videoLink: ''
          description: '<code>kd</code> is a CLI tool that allows you to use your local IDEs.'
          isDone: no
          order: 20
          skippable: yes


  initialize: ->

    @on actions.MARK_WELCOME_STEP_AS_DONE, @handleMarkAsDone

    @on actions.MIGRATION_AVAILABLE, @handleMigration


  handleMarkAsDone: (steps, { step }) ->

    steps.forEach (stepSet, role) ->
      return  unless stepSet.has step
      steps = steps.setIn [ role, step, 'isDone' ], yes

    return steps



  handleMigration: (steps) ->

    steps.setIn [ 'common', 'migrateFromKoding' ], toImmutable
      path: '/MigrateFromSolo'
      title: 'Migrate from Solo'
      actionTitle: 'Migrate'
      videoLink: ''
      description: 'You can migrate your solo machines to team!'
      isDone: no
      order: 30
      starred: yes
      skippable: yes
