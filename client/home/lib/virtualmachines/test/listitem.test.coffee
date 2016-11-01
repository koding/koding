React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TestUtils          = require 'react-addons-test-utils'
ListItem           = require '../components/machineslist/listitem'
mock               = require '../../../../mocks/mockingjay'
toImmutable        = require 'app/util/toImmutable'

describe 'ListItem', ->

  { Simulate,
    createRenderer,
    renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils

  machine = toImmutable mock.getMockJMachine()
  stack   = toImmutable mock.getMockComputeStack()

  describe '::render', ->

    it 'should render correct classNames', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<ListItem machine={machine} stack={stack} />)

      listitem = shallowRenderer.getRenderOutput()

      expect(listitem.props.className).toInclude 'MachinesListItem'


    it 'should render children with correct classNames', ->

      listitem = renderIntoDocument \
        <ListItem machine={machine} stack={stack} />

      listitem.setState { isDetailOpen:yes }

      machineLabel   = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-machineLabel'
      hostName       = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-hostName'
      stackLabel     = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-stackLabel'
      detailToggle   = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-detailToggle'
      machineDetails = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-machineDetails'

      expect(machineLabel).toExist()
      expect(hostName).toExist()
      expect(stackLabel).toExist()
      expect(detailToggle).toExist()
      expect(machineDetails).toExist()


    it 'should render machine label, hostname and stackLabel correctly', ->

      listitem = renderIntoDocument \
        <ListItem machine={machine} stack={stack} />

      machineLabel   = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-machineLabel'
      expect(machineLabel.innerHTML).toEqual machine.get 'label'

      hostName       = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-hostName'
      expect(hostName.innerHTML).toEqual machine.get('ipAddress') or '0.0.0.0'

      stackLabel     = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-stackLabel'
      expect(stackLabel.textContent).toEqual stack.get 'title'


  describe '::click', ->

    it 'should change state for isDetailOpen', ->

      listitem = renderIntoDocument \
        <ListItem machine={machine} stack={stack} />

      isDetailOpen = listitem.state.isDetailOpen

      detailToggle = findRenderedDOMComponentWithClass listitem, 'MachinesListItem-detailToggleButton'
      Simulate.click ReactDOM.findDOMNode(detailToggle)

      expect(isDetailOpen).toNotEqual listitem.state.isDetailOpen
