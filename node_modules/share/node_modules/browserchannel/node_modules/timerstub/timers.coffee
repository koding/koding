# We'll arbitrarily start the clock at 1 million ticks.
now = 1000000

# The queue contains [time, fn, repeat, id] tuples which will be executed in order, at the time specified.
#
# Elements are stored as an array for convenience. Inserting is O(N) - but since this is intended for
# testing, it shouldn't matter too much. This should probably be replaced with a proper priority queue
# at some stage.
queue = []

lastId = 0

# Insert a new element in the queue. repeat = number of ms before the function
# should be called again, or 0 if the function should not repeat.
#
# Supplying an id is optional. Returns id.
insert = (time, fn, repeat, id) ->
	i = 0
	++i while i < queue.length and queue[i][0] <= time
	id ?= ++lastId
	repeat ?= 0
	queue.splice i, 0, [time, fn, repeat, id]
	id

exports.setTimeout = (fn, timeout) ->
	if typeof fn is 'string' then fn = -> eval fn
	if timeout == 0
		process.nextTick fn
	else
		insert now + timeout, fn

exports.clearTimeout = (id) ->
	# This is a really inefficient way of doing it... instead I could loop through then splice().
	#
	# Eh.
	queue = (e for e in queue when e[3] != id)
	return

exports.setInterval = (fn, timeout) ->
	throw new Error 'Timer stubs dont support setInterval(fn, 0)' if timeout == 0
	if typeof fn is 'string' then fn = -> eval fn
	insert now + timeout, fn, timeout

exports.clearInterval = exports.clearTimeout

exports.Date = (time) -> new Date(time ? now)
exports.Date.now = -> now

exports.wait = (amt, callback) ->
	# Wait needs to be called on next tick, so its logic is wrapped.
	waitInternal = (amt) ->
		throw new Error 'amt must be a positive number' unless typeof amt == 'number' and amt >= 0

		if queue.length > 0 and now + amt >= queue[0][0]
			[time, fn, repeat, id] = queue.shift()
			amt -= time - now
			now = time
			if repeat
				insert now + repeat, fn, repeat, id
			fn()
			process.nextTick -> waitInternal amt, callback
		else
			now += amt
			callback() if callback?

	process.nextTick -> waitInternal amt

exports.waitAll = (callback) ->
	if queue.length == 0
		process.nextTick callback if callback?
	else
		exports.wait queue[0][0] - now, ->
			# wheeee async + recursion = fun!
			exports.waitAll(callback)

exports.clearAll = -> queue = []
