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

{ privateStackTemplates
  teamStackTemplates
  privateStacks
  teamStacks
  stacksWithMenuItems
  stacksWithMachines
  stacksWithTemplates
  draftStackTemplates
  sharedVMs } = require 'app/redux/modules/sidebar/stacks'


mapDispatchToProps = (dispatch) ->

  return {
    reinitStack: (stack, machines, template) ->
      dispatch(destroyStack stack, machines).then (res) ->
        handleRoute '/IDE'
        dispatch(initializeStack template).then  (res) ->
          # result[0] is always stack [1], [2] ... machines
          { result } = res
          machine = result[1]
          reloadIDE machine.label # we can extract label from res as well


    destroyStack: (stack, machines) ->
      dispatch(destroyStack stack, machines).then (res) ->
        handleRoute '/IDE'


    initializeStack: (template) ->
      dispatch(initializeStack template).then (res) ->
        # result[0] is always stack [1], [2] ... machines
        { result } = res
        machine = result[1]
        reloadIDE machine.label


    handleRoute: (route) ->
      handleRoute route
  }

mapStateToProps = (state) ->

  return {
    stacks: state.bongo['JComputeStack']
    privateStacks: privateStacks(state.bongo['JComputeStack']) or {}
    teamStacks: teamStacks(state.bongo['JComputeStack']) or {}
    stackTemplates: state.bongo['JStackTemplate'] or {}
    draftStackTemplates: draftStackTemplates(state.bongo['JComputeStack'], state.bongo['JStackTemplate'])
    stacksWithMenuItems: stacksWithMenuItems(state.bongo['JComputeStack'], state.bongo['JStackTemplate'], state.stacksWithRevisionStatus)
    stacksWithTemplates: stacksWithTemplates(state.bongo['JComputeStack'], state.bongo['JStackTemplate'])
    stacksWithMachines: stacksWithMachines(state.bongo['JComputeStack'], state.bongo['JMachine'])
    sharedVMs: sharedVMs(state.bongo['JMachine'])
  }


class SidebarContainer extends React.Component

  componentWillMount: ->

    { slug: group } = globals.currentGroup

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JComputeStack.some({ group })
    })

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JStackTemplate.some({ group })
    })

    @props.store.dispatch({
      types: [ LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL ]
      bongo: (remote) -> remote.api.JMachine.some({})
    })

  componentDidMount: ->

    kd.singletons.computeController.checkStackRevisions(@props.stacks)


  render: ->

    <Sidebar
      stacks={@props.stacks}
      teamStacks={@props.teamStacks}
      privateStacks={@props.privateStacks}
      stacksWithMachines={@props.stacksWithMachines}
      stacksWithTemplates={@props.stacksWithTemplates}
      draftStackTemplates={@props.draftStackTemplates}
      stacksWithMenuItems={@props.stacksWithMenuItems}
      stackTemplates={@props.stackTemplates}
      sharedVMs={@props.sharedVMs}
      reinitStack={@props.reinitStack}
      destroyStack={@props.destroyStack}
      handleRoute={@props.handleRoute}
      openOnGitlab={@props.openOnGitlab}
      initializeStack={@props.initializeStack} />


module.exports = connect(mapStateToProps, mapDispatchToProps)(SidebarContainer)
