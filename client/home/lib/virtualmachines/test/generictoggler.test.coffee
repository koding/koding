kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TestUtils          = require 'react-addons-test-utils'
GenericToggler     = require '../components/machineslist/generictoggler'


describe 'GenericToggler', ->

  { Simulate,
    createRenderer,
    renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils


  describe '::render', ->

    it 'should render correct classNames', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<GenericToggler onToggle={kd.noop}/>)

      generictoggler = shallowRenderer.getRenderOutput()


      expect(generictoggler.props.className).toInclude ' GenericToggler'
      expect(generictoggler.props.children.length).toEqual 2


    it 'should render correct props', ->
      onToggle = expect.createSpy()
      generictoggler = renderIntoDocument(<GenericToggler
        title={'title'}
        className={'className'}
        description={'description'}
        onToggle={onToggle}/>)

      title = findRenderedDOMComponentWithClass generictoggler, 'GenericToggler-title'
      expect(title.innerHTML).toInclude 'title'

      description = findRenderedDOMComponentWithClass generictoggler, 'GenericToggler-description'
      expect(description.innerHTML).toInclude 'description'

      toggle = generictoggler.refs.toggle
      toggle = ReactDOM.findDOMNode(toggle)
      toggle = toggle.querySelector 'input'

      Simulate.change toggle

      expect(onToggle).toHaveBeenCalled()
