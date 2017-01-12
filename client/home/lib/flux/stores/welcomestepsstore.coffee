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
          actionTitle: 'Create'
          miniTitle: 'Create a Stack'
          description: 'Create a blueprint for your team’s entire infrastructure.'
          isDone: no
          order: 1
          skippable: no
        enterCredentials :
          path: '/Stack-Editor'
          title: 'Enter your Credentials'
          actionTitle: 'Enter'
          videoLink: ''
          miniTitle: 'Enter Credentials'
          description: 'To set up your machines we need your cloud provider credentials.'
          isDone: no
          order: 2
          skippable: no
        buildStack :
          path: '/IDE'
          title: 'Build Your Stack'
          actionTitle: 'Build'
          videoLink: ''
          description: 'To access your VMs you need to build your stack.'
          isDone: no
          order: 3
          skippable: no
        inviteTeam :
          path: '/Home/my-team#send-invites'
          title: 'Invite Your Team'
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
          path: '/Home/koding-utilities#kd-cli'
          title: 'Install KD'
          actionTitle: 'Install'
          videoLink: ''
          description: '<code>kd</code> is a CLI tool that allows you to use your local IDEs.'
          isDone: no
          order: 20
          skippable: yes
        gitlabIntegration :
          path: '/Home/my-account#integrations'
          title: 'Connect GitLab'
          actionTitle: 'Setup'
          videoLink: ''
          description: 'Start working with existing projects with your GitLab integration'
          isDone: no
          order: 21
          skippable: yes
        githubIntegration :
          path: '/Home/my-account#integrations'
          title: 'Connect GitHub'
          actionTitle: 'Setup'
          videoLink: ''
          description: 'Start working with existing projects with your GitHub integration'
          isDone: no
          order: 22
          skippable: yes


  initialize: ->

    @on actions.MARK_WELCOME_STEP_AS_DONE, @handleMarkAsDone


  handleMarkAsDone: (steps, { step }) ->

    steps.forEach (stepSet, role) ->
      return  unless stepSet.has step
      steps = steps.setIn [ role, step, 'isDone' ], yes

    return steps
