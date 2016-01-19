# to be able to test i am using relative requires for now. ~Umut
KDStateMachine = require '../../../app/lib/statemachine'

module.exports = class CollaborationStateMachine extends KDStateMachine

  states: [
    'Initial', 'Loading', 'ErrorLoading', 'Resuming', 'NotStarted', 'Preparing'
    'ErrorPreparing', 'Prepared', 'Creating', 'ErrorCreating', 'Active', 'Ending'
    'Created'
    # 'ErrorResuming_'
  ]

  transitions:
    Initial       : ['Loading']
    Loading       : ['NotStarted', 'Resuming', 'ErrorLoading']
    ErrorLoading  : ['Loading']
    Resuming      : ['Active']
    NotStarted    : ['Preparing', 'Loading']
    Preparing     : ['Prepared', 'ErrorPreparing']
    ErrorPreparing: ['Preparing', 'NotStarted']
    Prepared      : ['Creating']
    Creating      : ['ErrorCreating', 'Created']
    Created       : ['Active']
    ErrorCreating : ['Creating', 'Prepared']
    Active        : ['Ending']
    Ending        : []
