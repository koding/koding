React         = require 'react/addons'
{ expect }    = require 'chai'
{ TestUtils } = React.addons
helper        = require '../helper'

ProfileLink = require '../profilelink'

describe 'ProfileLink', ->

  ProfileLink = require '../profilelink'

  it 'takes an account renders a link to user', ->

    account = { profile: { nickname: 'FooUser' } }

    profileLink = TestUtils.renderIntoDocument(
      <ProfileLink account={account} />
    )

    link = TestUtils.findRenderedDOMComponentWithTag profileLink, 'a'

    [..., slug] = link.getDOMNode().href.split('/')

    expect(slug).toEqual 'FooUser'


  it 'takes an optional callback as onClick handler', ->

    account = helper.defaultAccount()

    flag = no

    onClick = -> flag = yes

    profileLink = TestUtils.renderIntoDocument(
      <ProfileLink account={account} onClick={onClick} />
    )

    link = TestUtils.findRenderedDOMComponentWithTag profileLink, 'a'

    TestUtils.Simulate.click link

    expect(flag).toEqual yes
