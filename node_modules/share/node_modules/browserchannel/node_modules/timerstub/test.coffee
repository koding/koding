# Nodeunit test suite.
#
# Run with:
#  % nodeunit test.coffee

{testCase} = require 'nodeunit'

timers = require './timers'
# We'll override these global variables with local variables with the same names
{setTimeout, clearTimeout, setInterval, clearInterval, Date} = timers

doneOnce = (test) ->
	done = false
	->
		throw new Error 'Already called method' if done
		done = true
		test.done()


module.exports = testCase
	setUp: (callback) ->
		timers.clearAll()
		callback()

	# Timeout

	'setTimeout(n) calls the method after n ms': (test) ->
		called = 0
		setTimeout (-> called++), 1000

		test.strictEqual called, 0, 'method called immediately'
		timers.wait 999, ->
			test.strictEqual called, 0, 'method called too early'
			timers.wait 1, ->
				test.strictEqual called, 1, 'method not called at the right time'
				timers.wait 100000, ->
					test.strictEqual called, 1, 'method called again'
					test.done()

	'setTimeout(0) calls the method on next tick': (test) ->
		called = 0
		setTimeout (-> called++), 0

		test.strictEqual called, 0, 'Method called immediately'
		process.nextTick ->
			test.strictEqual called, 1, 'Method not called after nextTick'
			test.done()
	
	'setTimeout() calls methods at the right time': (test) ->
		start = Date.now()
		setTimeout (-> test.strictEqual Date.now(), start + 1000), 1000
		timers.wait 100000, -> test.done()

	'Cancelling a timeout immediately works': (test) ->
		called = 0
		timeout = setTimeout (-> called++), 1000
		clearTimeout timeout
		timers.wait 100000, ->
			test.strictEqual called, 0
			test.done()

	'Cancelling a timeout after some time works': (test) ->
		called = 0
		timeout = setTimeout (-> called++), 1000

		timers.wait 999, ->
			clearTimeout timeout
			timers.wait 100000, ->
				test.strictEqual called, 0
				test.done()
	
	# Intervals
	
	'Setting an interval works': (test) ->
		called = 0
		setInterval (-> called++), 1000

		timers.wait 999, ->
			test.strictEqual called, 0, 'interval called too early'
			timers.wait 1, ->
				test.strictEqual called, 1, 'interval not called at the right time'
				timers.wait 5000, ->
					test.strictEqual called, 6, 'interval not called at the right time'
					test.done()
	
	'Cancelling an interval immediately works': (test) ->
		called = 0
		id = setInterval (-> called++), 1000
		clearInterval id
		timers.wait 100000, ->
			test.strictEqual called, 0
			test.done()

	'Cancelling an interval after some time works': (test) ->
		called = 0
		id = setInterval (-> called++), 1000

		timers.wait 1001, ->
			test.strictEqual called, 1
			clearInterval id
			timers.wait 100000, ->
				test.strictEqual called, 1
				test.done()

	'An interval which cancels itself works': (test) ->
		called = 0
		id = setInterval (-> called++; clearInterval id), 1000

		timers.wait 10000, ->
			test.strictEqual called, 1
			test.done()

	# Date

	'Date.now() returns a number': (test) ->
		start = Date.now()
		test.strictEqual typeof start, 'number'
		test.done()

	'Date.now() returns increasing values over time': (test) ->
		start = Date.now()
		timers.wait 1000, ->
			end = Date.now()
			test.strictEqual end, start + 1000
			test.done()
	
	'Date.now()s value doesnt change with timers.wait 0': (test) ->
		start = Date.now()
		timers.wait 0, ->
			test.strictEqual Date.now(), start
			test.done()
	
	'new Date() returns a normal date object set to now': (test) ->
		d = new Date()
		test.ok d.toISOString()
		test.strictEqual d.getTime(), Date.now()
		test.done()

	'new Date(time) returns a normal date object': (test) ->
		d = new Date(1317391735268)
		test.strictEqual d.toISOString(), '2011-09-30T14:08:55.268Z'
		test.done()

	# Wait

	'timers.wait is asynchronous': (test) ->
		v = true
		timers.wait 1000, ->
			test.strictEqual v, false
			test.done()
		v = false
	
	'timers.wait(0) is asynchronous': (test) ->
		v = true
		timers.wait 0, ->
			test.strictEqual v, false
			test.done()
		v = false
	
	'timers.wait with no callback works': (test) ->
		setTimeout (->), 1000
		# This might crash now, or it might crash later...
		timers.wait 500
		process.nextTick ->
			timers.wait 1000
			process.nextTick ->
				test.done()

	'timers.wait(1000) doesnt move the clock forward immediately': (test) ->
		start = Date.now()
		timers.wait 500
		test.strictEqual Date.now(), start
		test.done()

	# Wait All
	
	'timers.waitAll() calls queued callback': (test) ->
		called = 0
		setTimeout (-> called++), 1000
		timers.waitAll ->
			test.strictEqual called, 1
			test.done()
	
	'date is advanced only as far as it need to': (test) ->
		start = Date.now()
		setTimeout (->), 1000
		timers.waitAll ->
			test.strictEqual start + 1000, Date.now()
			test.done()

	'timers.waitAll() with nothing queued does nothing': (test) ->
		start = Date.now()
		timers.waitAll ->
			test.strictEqual start, Date.now()
			test.done()
	
	'timers.waitAll with no callback does not crash': (test) ->
		start = Date.now()
		timers.waitAll()
		test.strictEqual start, Date.now()
		test.done()
	
	'waitAll works with an interval': (test) ->
		called = false
		t = setInterval (->
			throw new Error 'already called' if called
			called = true
			clearInterval t
			), 1000

		timers.waitAll ->
			test.strictEqual called, true
			test.done()

	# clearAll
	
	'cleared stuff doesnt get called': (test) ->
		setTimeout (-> throw new Error 'should not be called'), 1000
		setInterval (-> throw new Error 'should not be called'), 1000
		setInterval (-> throw new Error 'should not be called'), 500

		timers.wait 499, ->
			timers.clearAll()
			timers.wait 10000, ->
				test.done()
	

	# Integration
	
	'lots of timers are called in order': (test) ->
		start = Date.now()
		called = 0
		for _ in [1..1000]
			do ->
				interval = Math.floor(Math.random() * 500)
				setTimeout (-> called++; test.strictEqual Date.now(), start + interval, "int #{interval}"), interval

		timers.wait 500, ->
			test.strictEqual called, 1000
			test.done()

	'lots of timers are called in order with timers.waitAll': (test) ->
		# Same as the above test except timers.waitAll() instead of timers.wait()
		start = Date.now()
		called = 0
		for _ in [1..1000]
			do ->
				interval = Math.floor(Math.random() * 500)
				setTimeout (-> called++; test.strictEqual Date.now(), start + interval, "int #{interval}"), interval

		timers.waitAll ->
			test.strictEqual called, 1000
			test.done()

