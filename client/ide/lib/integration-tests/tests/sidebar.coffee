$ = require 'jquery'

# It is important that you should restore your current state,
# after each test. If not, you will break the sync testing.
describe 'SidebarMenu', ->
  beforeEach (done) ->
    console.log('before')
    $('.WelcomeSteps-miniview--count.in').click()
    done()

  afterEach (done) ->
    console.log('after')
    $('.WelcomeSteps-miniview.in ul.bullets').click()
    done()

  it 'should open on team click', (done) ->
    console.log('done')
    expert = $('.WelcomeSteps-miniview.in')
    should(expert).exist
    done()
