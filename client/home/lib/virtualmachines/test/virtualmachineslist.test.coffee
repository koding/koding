kd                    = require 'kd'
React                 = require 'app/react'
ReactDOM              = require 'react-dom'
expect                = require 'expect'
TestUtils             = require 'react-addons-test-utils'
VirtualMachinesList   = require '../components/virtualmachineslist/'
mock                  = require '../../../../mocks/mockingjay'
toImmutable           = require 'app/util/toImmutable'


describe 'VirtualMachinesList', ->

  { renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils


  describe '::render', ->

    it 'should render correct children', ->

      stacks = {}
      stack = mock.getMockComputeStack()
      stacks[stack._id] = toImmutable stack
      stacks = toImmutable stacks

      listitem = renderIntoDocument(<VirtualMachinesList.Container />)
      listitem.setState {stacks}

      result = findRenderedDOMComponentWithClass listitem, 'MachinesListItem'
      expect(result).toExist()
