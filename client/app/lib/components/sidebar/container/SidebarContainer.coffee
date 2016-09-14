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
  reloadIDE } = require 'app/redux/modules/sidebar/stacks'

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
  }

mapStateToProps = (state) ->

  return {
    sidebarStacks: sidebarStacks(state)
    stacksAndMachines: stacksAndMachines(state)
    stacksAndTemplates: stacksAndTemplates(state)
    stacksAndCredential: stacksAndCredential(state)
    stacksAndMenuItems: stacksAndMenuItems(state)
    sharedVMs: sharedVMs(state)
    # stacks: bongo.all('JComputeStack')(state)
    # privateStacks: privateStacks(state)
    # teamStacks: teamStacks(state.bongo['JComputeStack']) or {}
    # stackTemplates: state.bongo['JStackTemplate'] or {}
    # draftStackTemplates: draftStackTemplates(state.bongo['JComputeStack'], state.bongo['JStackTemplate'])
    # stacksAndMenuItems: stacksAndMenuItems(state.bongo['JComputeStack'], state.bongo['JStackTemplate'], state.stacksWithRevisionStatus)
    # stacksAndTemplates: stacksAndTemplates(state.bongo['JComputeStack'], state.bongo['JStackTemplate'])
    # stacksAndMachines: stacksAndMachines(state.bongo['JComputeStack'], state.bongo['JMachine'])
    # sharedVMs: sharedVMs(state.bongo['JMachine'])
    # stacksAndCredential: stacksAndCredential(state.bongo['JComputeStack'], state.bongo['JStackTemplate'])
  }


class SidebarContainer extends React.Component

  componentWillMount: ->

    { slug: group } = globals.currentGroup
    { computeController } = kd.singletons

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JComputeStack.some({ group }).then (stacks) ->
        computeController.checkStackRevisions stacks
        return stacks
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


  render: ->

    <Sidebar {...@props} />


module.exports = connect(mapStateToProps, mapDispatchToProps)(SidebarContainer)
