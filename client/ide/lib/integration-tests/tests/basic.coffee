describe 'Should assertion library', ->
  it 'should equal perfectly', ->
    5.should.equal 5


describe 'Array', ->
  it 'should return true on isArray', ->
    Array.isArray([]).should.equal yes
