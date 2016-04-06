kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
expect                = require 'expect'
TestUtils             = require 'react-addons-test-utils'
PrivateStacksList     = require '../components/privatestackslist/'
mock                  = require '../../../../mocks/mockingjay'
toImmutable           = require 'app/util/toImmutable'


describe 'PrivateStacksList', ->

 { renderIntoDocument,
   findRenderedDOMComponentWithClass } = TestUtils


 describe '::render', ->

  it 'should render correct children', ->

    templates={}
    template = mock.getPrivateStackTemplate()
    templates[template._id] = toImmutable template
    templates = toImmutable templates

    listitem = renderIntoDocument(<PrivateStacksList.Container />)
    listitem.setState {templates}

    result = findRenderedDOMComponentWithClass listitem, 'StackTemplateItem'
    expect(result).toExist()

  it 'should render correct machine title ', ->

    templates={}
    template = mock.getPrivateStackTemplate()
    templates[template._id] = toImmutable template
    templates = toImmutable templates

    listitem = renderIntoDocument(<PrivateStacksList.Container />)
    listitem.setState {templates}

    result = findRenderedDOMComponentWithClass listitem, 'StackTemplateItem-label'
    expect(result.innerHTML).toEqual template.title