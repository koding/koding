React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TestUtils          = require 'react-addons-test-utils'
MachineDetails     = require '../components/machineslist/machinedetails'
mock               = require '../../../../mocks/mockingjay'
toImmutable        = require 'app/util/toImmutable'


describe 'MachineDetails', ->

  { createRenderer,
    renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils

  machine = toImmutable mock.getMockJMachine()

  describe '::render', ->

    it 'should render view with correct className ', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<MachineDetails machine={machine} />)

      machinedetails = shallowRenderer.getRenderOutput()


      expect(machinedetails.props.className).toInclude 'MachineDetails'
      expect(machinedetails.props.children.length).toEqual 4


    it 'should render view with correct children ', ->

      machinedetails = renderIntoDocument(<MachineDetails
        machine={machine}
        shouldRenderSpecs={yes}
        />)

      specslist = findRenderedDOMComponentWithClass machinedetails, 'MachineDetails-SpecsList'

      expect(specslist).toExist()

      shallowRenderer = createRenderer()
      shallowRenderer.render(<MachineDetails
        machine={machine}
        shouldRenderSpecs={yes}
        shouldRenderAlwaysOn={yes}
        shouldRenderSharing={yes}/>)

      machinedetails = shallowRenderer.getRenderOutput()

      expect(machinedetails.props.children[1].props.title).toEqual 'VM Power'
      expect(machinedetails.props.children[2].props.title).toEqual 'Always On'
      expect(machinedetails.props.children[3].props.title).toEqual 'VM Sharing'
