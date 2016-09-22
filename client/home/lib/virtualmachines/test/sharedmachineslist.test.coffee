kd                    = require 'kd'
React                 = require 'app/react'
ReactDOM              = require 'react-dom'
expect                = require 'expect'
TestUtils             = require 'react-addons-test-utils'
SharedMachinesList    = require '../components/sharedmachineslist/'
mock                  = require '../../../../mocks/mockingjay'
toImmutable           = require 'app/util/toImmutable'


describe 'SharedMachinesList', ->

  { renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils


  describe '::render', ->

    it 'should render correct children', ->

      machines = {}

      machines[mock.getMockMachine()._id] = toImmutable mock.getMockMachine()
      machines = toImmutable machines
      machineslist = renderIntoDocument(<SharedMachinesList.Container />)
      machineslist.setState {machines}

      result = findRenderedDOMComponentWithClass machineslist, 'MachinesListItem'
      expect(result).toExist()
