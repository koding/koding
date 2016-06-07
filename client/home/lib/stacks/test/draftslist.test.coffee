kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
expect                = require 'expect'
TestUtils             = require 'react-addons-test-utils'
DraftsList            = require '../components/draftslist/'
mock                  = require '../../../../mocks/mockingjay'
toImmutable           = require 'app/util/toImmutable'


describe 'DraftsList', ->

 { renderIntoDocument,
   findRenderedDOMComponentWithClass } = TestUtils


 describe '::render', ->

  it 'should render correct children', ->

    templates={}
    template = mock.getDraftStackTemplate() # check template title
    templates[template._id] = toImmutable template
    templates = toImmutable templates

    listitem = renderIntoDocument(<DraftsList.Container />)
    listitem.setState {templates}

    result = findRenderedDOMComponentWithClass listitem, 'StackTemplateItem'
    expect(result).toExist()

  it 'should render correct machine title ', ->

    templates={}
    template = mock.getDraftStackTemplate() # check template title
    templates[template._id] = toImmutable template
    templates = toImmutable templates

    listitem = renderIntoDocument(<DraftsList.Container />)
    listitem.setState {templates}

    result = findRenderedDOMComponentWithClass listitem, 'HomeAppViewListItem-label'
    expect(result.innerHTML).toEqual template.title