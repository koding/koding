kd                    = require 'kd'
React                 = require 'app/react'
ReactDOM              = require 'react-dom'
expect                = require 'expect'
TestUtils             = require 'react-addons-test-utils'
ConnectedMachinesList = require '../components/connectedmachineslist/'
mock                  = require '../../../../mocks/mockingjay'
toImmutable           = require 'app/util/toImmutable'
immutable             = require 'immutable'
List                  = require 'app/components/list'


describe 'ConnectedMachinesList', ->

  { renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils


  describe '::render', ->

    it 'should render correct children', ->

      stacks = {}
      stack = mock.getMockComputeStack()
      stack.title = 'managed vms'
      stacks[stack._id] = toImmutable stack
      stacks = toImmutable stacks

      listitem = renderIntoDocument(<ConnectedMachinesList.Container />)
      listitem.setState {stacks}

      result = findRenderedDOMComponentWithClass listitem, 'MachinesListItem'

      expect(result).toExist()
