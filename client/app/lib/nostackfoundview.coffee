kd = require 'kd'
React = require 'app/react'
globals = require 'globals'
ReactView = require 'app/react/reactview'
canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'

module.exports = class NoStackFoundView extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'NoStackFoundView', options.cssClass

    super options, data

    # dirty - SY
    { mainController, mainView } = kd.singletons
    mainController.ready @bound 'viewAppended'
    mainView.on 'IntroVideoViewIsShown', @bound 'viewAppended'
    mainView.on 'IntroVideoViewIsHidden', @bound 'viewAppended'

  onClick: (event) ->

    { utils, singletons: { router } } = kd

    utils.stopDOMEvent event
    router.handleRoute '/Stack-Editor/New'


  renderReact: ->

    { computeController, mainView } = kd.singletons

    return <div/>  unless globals.userRoles
    return <div/>  if mainView.introVideoViewIsShown

    if isAdmin()

      <div className="NoStackFoundView-wrapper">
        <h2>Create a stack for your team</h2>
        <p>
          We will guide you through setting up a stack on Koding. Your stacks
          will be used to build and manage your dev environment for your whole team.
          You can read more information about stacks <a href="https://www.koding.com/docs/creating-an-aws-stack">here</a>.
        </p>
        <div className='ButtonContainer'>
          <button className='GenericButton' onClick={@bound 'onClick'}>CREATE A TEAM STACK</button>
        </div>
      </div>

    else if not canCreateStacks()

      <div className="NoStackFoundView-wrapper">
        <h2>Your Team Stack is Pending</h2>
        <p>
          Your team admins haven&apos;t created your stack yet.
          Unfortunately there is not much you can do at this moment.
          Please contact your team admin.
        </p>
      </div>

    else

      <div className="NoStackFoundView-wrapper">
        <h2>Your Team Stack is Pending</h2>
        <p>
          Your team admins haven&apos;t created your stack yet. If you want to experiment
          the stacks you can go ahead and create a personal stack.
          We will guide you through setting up a stack on Koding. You can read more
          information about stacks <a href="https://www.koding.com/docs/creating-an-aws-stack">here</a>.
        </p>
        <div className='ButtonContainer'>
          <button className='GenericButton' onClick={@bound 'onClick'}>CREATE A PERSONAL STACK</button>
        </div>
      </div>
