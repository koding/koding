_             = require 'lodash'
React         = require 'react/addons'
{ expect }    = require 'chai'
{ TestUtils } = React.addons
helper        = require '../helper'

ProfileText = require '../profiletext'

describe 'ProfileText', ->

  it 'works', ->

    expect(<ProfileText />).to.be.ok

  it 'takes an account prints nice display name', ->

    profileText = TestUtils.renderIntoDocument(
      <ProfileText account={helper.defaultAccount()} />
    )

    span = TestUtils.findRenderedDOMComponentWithTag profileText, 'span'

    expect(span.getDOMNode().textContent).toEqual 'a koding user'


  it 'prints nickname if firstname or lastname not present', ->

    accountWithOnlyNickname = helper.namelessAccount 'asd'

    profileText = TestUtils.renderIntoDocument(
      <ProfileText account={accountWithOnlyNickname} />
    )

    span = TestUtils.findRenderedDOMComponentWithTag profileText, 'span'

    expect(span.getDOMNode().textContent).toEqual 'foouser'


  it 'adds a troll indicator if user is exempt', ->

    account = helper.defaultTrollAccount()

    profileText = TestUtils.renderIntoDocument(
      <ProfileText account={account} />
    )

    span = TestUtils.findRenderedDOMComponentWithTag profileText, 'span'

    isTroll = _.includes span.getDOMNode().textContent, '(T)'

    expect(isTroll).toEqual yes
