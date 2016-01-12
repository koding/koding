React                = require 'react/addons'
expect               = require 'expect'
ActivityAppComponent = require '../appcomponent'
TestUtils            = require 'react-addons-test-utils'

describe 'ActivityAppComponent', ->

  { renderIntoDocument
    findRenderedDOMComponentWithClass
    scryRenderedDOMComponentsWithClass } = TestUtils


  it 'renders appComponent with classNames by given props', ->

    appComponent = renderIntoDocument(
      <ActivityAppComponent />
    )

    isWithModal           = scryRenderedDOMComponentsWithClass appComponent, 'is-withModal'
    isWithContent         = scryRenderedDOMComponentsWithClass appComponent, 'is-withContent'
    appComponentClassName = scryRenderedDOMComponentsWithClass appComponent, 'ActivityAppComponent'

    expect(appComponentClassName.length).toEqual 1
    expect(isWithContent.length).toEqual 0
    expect(isWithModal.length).toEqual 0


  it 'renders given content and modal into appComponent', ->

    content = <div className='AppComponent-content'>content</div>
    modal   = <div className='AppComponent-modal'>modal</div>

    appComponent = renderIntoDocument(
      <ActivityAppComponent
        modal={modal}
        content={content} />
    )

    modal         = findRenderedDOMComponentWithClass appComponent, 'AppComponent-modal'
    content       = findRenderedDOMComponentWithClass appComponent, 'AppComponent-content'
    isWithModal   = scryRenderedDOMComponentsWithClass appComponent, 'is-withModal'
    isWithContent = scryRenderedDOMComponentsWithClass appComponent, 'is-withContent'

    expect(content.className).toEqual 'AppComponent-content'
    expect(modal.className).toEqual 'AppComponent-modal'
    expect(isWithModal.length).toEqual 1
    expect(isWithContent.length).toEqual 1

