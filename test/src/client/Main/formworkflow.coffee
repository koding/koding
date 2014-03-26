assert = require 'assert'

results = null

make = ->
  fw = new FormWorkflow
  fw.on 'DataCollected', (data) -> results.push data
  fw

module.exports = [
  ->
    results = []
    test.call make() for test in tests
    results = null
    log "FormWorkflow tests passed"
    yes
]

tests = [
  ->
    @requireData [
      'foo'
      'bar'
    ]

    @collectData { foo: 42 }

    assert not @isSatisfied()

    @collectData { bar: 0 }

    assert @isSatisfied()

    assert results.length is 1
  ->
    @requireData @all(
      'foo'
      'bar'
    )

    @collectData { foo: 42 }

    assert not @isSatisfied()

    @collectData { bar: 0 }

    assert @isSatisfied()

    assert results.length is 2

  ->
    @requireData @any(
      'foo'
      'bar'
    )

    @collectData { foo: 42 }

    assert @isSatisfied()

    assert results.length is 3

    @collectData { bar: 0 }

    assert @isSatisfied()

    assert results.length is 4

    @clearData 'foo'

    assert @isSatisfied()

    assert results.length is 5

    @clearData 'bar'

    assert not @isSatisfied()
  ->
    @requireData @all(
      'foo'
      'bar'
      @any('baz', 'qux')
    )

    @collectData { foo: 42 }

    assert not @isSatisfied()

    @collectData { bar: 0 }

    assert not @isSatisfied()

    @collectData { baz: 16 }

    assert @isSatisfied()

    assert results.length is 6

    @clearData 'baz'

    assert not @isSatisfied()

    @collectData { qux: -88 }

    assert @isSatisfied()

    assert results.length is 7

    @clearData 'bar'

    assert not @isSatisfied()
]