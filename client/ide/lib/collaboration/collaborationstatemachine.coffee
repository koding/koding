# to be able to test i am using relative requires for now. ~Umut
KDStateMachine = require '../../../app/lib/statemachine'

module.exports = class CollaborationStateMachine extends KDStateMachine

  states: [
    'Loading', 'ErrorLoading', 'Resuming', 'NotStarted', 'PreCreated'
    'Creating', 'ErrorCreating', 'Active', 'Ending'
    # 'ErrorResuming_'
  ]

  transitions:
    Loading       : ['NotStarted', 'Resuming', 'ErrorLoading']
    ErrorLoading  : ['Loading']
    Resuming      : ['Active']
    NotStarted    : ['PreCreated']
    PreCreated    : ['Creating']
    Creating      : ['ErrorCreating']
    ErrorCreating : ['Creating', 'NotStarted']
    Active        : ['Ending']
    Ending        : []
