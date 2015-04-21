# to be able to test i am using relative requires for now. ~Umut
KDStateMachine = require '../../../app/lib/statemachine'

module.exports = class CollaborationStateMachine extends KDStateMachine

  states: [
    'Loading', 'ErrorLoading', 'Resuming', 'NotStarted', 'Preparing'
    'ErrorPreparing', 'Prepared', 'Creating', 'ErrorCreating', 'Active', 'Ending'
    # 'ErrorResuming_'
  ]

  transitions:
    Loading       : ['NotStarted', 'Resuming', 'ErrorLoading']
    ErrorLoading  : ['Loading']
    Resuming      : ['Active']
    NotStarted    : ['Preparing', 'Loading']
    Preparing     : ['Prepared', 'ErrorPreparing']
    ErrorPreparing: ['Preparing', 'NotStarted']
    Prepared      : ['Creating']
    Creating      : ['ErrorCreating', 'Active']
    ErrorCreating : ['Creating', 'NotStarted']
    Active        : ['Ending']
    Ending        : []
