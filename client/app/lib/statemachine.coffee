machina = require 'machina'
_ = require 'lodash'

module.exports = class StateMachine extends machina.Fsm

  ###*
   * Abstract StateMachine class.
   *
   * Usage Example:
   *
   *     class FooMachine extends KDStateMachine
   *       states: ['Loading', 'Activating', 'Active', 'Terminating', 'Terminated']
   *       transitions:
   *         Loading     : ['Activating', 'Terminated']
   *         Activating  : ['Active']
   *         Active      : ['Terminating']
   *         Terminating : ['Terminated']
   *
   *      machine = new FooMachine
   *        stateHandlers:
   *          Loading : -> console.log 'onLoadingState'
   *          Active  : -> console.log 'onActiveState'
  ###
  constructor: (options = {}, data) ->

    options = @transformOptions options

    super options


  ###*
   * Gets regular options,
   *   - Machinafy states
   *   - assigns the first state.
   *
   * @param {object} options
   * @param {object} options.stateHandlers - an object that holds handlers for states.
   * @return {object} transformedOptions - machina ready options to be passed.
  ###
  transformOptions: (options) ->

    states  = machinafyStates @states, options.stateHandlers
    options = _.assign {}, options, { states, initialState: @states[0] }

    return options


  ###*
   * Adds extra guards to machina's original transition method.
   *
   * It checks `transitions` object to see if it's ok to transition to next state.
   * If not throws an error.
   * Check happens as following:
   *
   *     class FooStateMachine extends KDStateMachine
   *       states: ['loading', 'active', 'terminating', 'terminated']
   *       transitions:
   *         { loading: ['active', 'terminated'] }
   *
   *     # initial state is first state from array
   *     machine = new FooStateMachine
   *
   *     # this will throw an error because it's not
   *     # in the transitions array of loading state.
   *     # and state will not be changed.
   *     machine.transition 'terminating'
   *     console.log machine.state # => 'loading'
   *
   *     # this will work as usual, active state is present
   *     # in the transitions array of loading state.
   *     machine.transition 'active'
   *
   * @param {string} next - state name to be transitioned into
  ###
  transition: (next) ->

    if @state
      unless next in @transitions[@state]
        return console.warn "illegal state transition from: #{@state}, to: #{next}"

    super next

###*
 * Transforms states array into machina ready states object.
 * If a handler with the key of state name is present, it attaches
 * that handler into machina-ready-options-object's `_onEnter` method.
 *
 * @param {Array.<string>} states - KDStateMachine states array
 * @param {object=} stateHandlers - handlers for states
 * @return {object} machinafiedStates
###
machinafyStates = (states, stateHandlers = {}) ->

  states = states.reduce (newStates, stateName) ->

    newStates[stateName] = state = {}

    # if a handler is present attach that into
    # `_onEnter` method so that machina will call it
    # automatically.
    if handler = stateHandlers[stateName]
      state._onEnter = handler

    return newStates
  , {}

  return states
