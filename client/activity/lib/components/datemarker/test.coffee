React      = require 'react/addons'
ReactDOM   = require 'react-dom'
expect     = require 'expect'
DateMarker = require '../datemarker'
TestUtils  = require 'react-addons-test-utils'

describe 'DateMarker', ->

  { renderIntoDocument
    isCompositeComponent
    findRenderedDOMComponentWithClass
    scryRenderedDOMComponentsWithClass } = TestUtils


  it 'renders a date container with given className', ->

    date           = new Date()
    className      = 'DateMarker-tests'
    fixedClassName = 'DateMarker-fixed'

    dateMarker = renderIntoDocument(
      <DateMarker date={date} className={className} />
    )

    markers     = scryRenderedDOMComponentsWithClass dateMarker, className
    fixedMarker = findRenderedDOMComponentWithClass dateMarker, fixedClassName

    expect(markers.length).toEqual 2
    expect(fixedMarker.className).toContain fixedClassName


  it 'takes a date and renders a date string like; Today, Yesterday ...', ->

    date                 = new Date()
    yesterday            = date.setDate date.getDate() - 1
    dateMarker_today     = renderIntoDocument(<DateMarker date={new Date()} />)
    dateMarker_yesterday = renderIntoDocument(<DateMarker date={yesterday} />)
    fixed_today          = ReactDOM.findDOMNode dateMarker_today.refs['DateMarker-fixed']
    fixed_yesterday      = ReactDOM.findDOMNode dateMarker_yesterday.refs['DateMarker-fixed']

    expect(isCompositeComponent dateMarker_today).toBeTruthy()
    expect(fixed_today.textContent).toEqual 'Today'
    expect(fixed_yesterday.textContent).toEqual 'Yesterday'

