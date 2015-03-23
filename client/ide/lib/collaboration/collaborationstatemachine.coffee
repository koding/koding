# to be able to test i am using relative requires for now. ~Umut
KDStateMachine = require '../../../app/lib/statemachine'

module.exports = class CollaborationStateMachine extends KDStateMachine

  states: [
    'Loading', 'ErrorLoading', 'Resuming', 'NotStarted', 'Preparing'
    'Prepared', 'Creating', 'ErrorCreating', 'Active', 'Ending'
    # 'ErrorResuming_'
  ]

  transitions:
    Loading       : ['NotStarted', 'Resuming', 'ErrorLoading']
    ErrorLoading  : ['Loading']
    Resuming      : ['Active']
    NotStarted    : ['Preparing']
    Preparing     : ['Prepared']
    Prepared      : ['Creating']
    Creating      : ['ErrorCreating', 'Active']
    ErrorCreating : ['Creating', 'NotStarted']
    Active        : ['Ending']
    Ending        : []
