kd = require 'kd'
React = require 'react'
{ connect } = require 'react-redux'
Sidebar = require 'component-lab/Sidebar'
globals = require 'globals'
{ LOAD } = require 'app/redux/modules/bongo'

{ reinitStack
  destroyStack
  initializeStack
  handleRoute
  openOnGitlab
  reloadIDE
  makeTeamDefault } = require 'app/redux/modules/sidebar/stacks'

{ sidebarStacks
  privateStackTemplates
  teamStackTemplates
  privateStacks
  teamStacks
  stacksAndMenuItems
  stacksAndMachines
  stacksAndTemplates
  draftStackTemplates
  stacksAndCredential

  sharedVMs } = require 'app/redux/modules/sidebar/stacks'


mapDispatchToProps = (dispatch) ->

  return {
    reinitStack: (stack, machines, template) ->
      reinitStack(stack, machines, template)(dispatch)

    destroyStack: (stack, machines) ->
      dispatch(destroyStack stack, machines)

    initializeStack: (template) ->
      initializeStack(template)(dispatch)

    handleRoute: (route) ->
      handleRoute route

    makeTeamDefault: (template, credential) ->
      makeTeamDefault template, credential, ->
        console.log 'haydadadas'
  }

mapStateToProps = (state) ->

  return {
    sidebarStacks: sidebarStacks(state)
    stacksAndMachines: stacksAndMachines(state)
    stacksAndTemplates: stacksAndTemplates(state)
    stacksAndCredential: stacksAndCredential(state)
    stacksAndMenuItems: stacksAndMenuItems(state)
    sharedVMs: sharedVMs(state)
    sharedVMs: sharedVMs(state)
  }


class SidebarContainer extends React.Component

  componentWillMount: ->

    { slug: group } = globals.currentGroup
    { computeController } = kd.singletons

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JComputeStack.some({ group })
    })

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JStackTemplate.some({ group }).then (stackTemplates) ->
        computeController.fetchCredentials stackTemplates
        return stackTemplates
    })

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JMachine.some({})
    })
    # get current team
    @props.store.dispatch {
      types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
      bongo: (remote) -> Promise.resolve(remote.revive globals.currentGroup)
    }


  render: ->

    # console.log 'props', @props

    <Sidebar {...@props} />


module.exports = connect(mapStateToProps, mapDispatchToProps)(SidebarContainer)
