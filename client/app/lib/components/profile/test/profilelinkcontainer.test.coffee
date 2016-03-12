{ expect }    = require 'chai'
React         = require 'react/addons'
{ TestUtils } = React.addons

ProfileLinkContainer = require '../profilelinkcontainer'


describe 'ProfileLinkContainer', ->

  it 'works', ->

    link = TestUtils.renderIntoDocument(
      <ProfileLinkContainer />
    )

    expect(link).to.be.ok


  describe 'async', ->

    it 'fetches account if an origin is passed', ->

      # still need to figure out async testing with react, especially the ones
      # in lifecycle methods, `e.g componentDidMount, etc.` since React components
      # are opaque data structures. I guess we will have to come up with some extra
      # conventions. This needs to be discussed. ~Umut
