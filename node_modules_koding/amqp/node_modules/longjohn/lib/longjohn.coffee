{EventEmitter} = require 'events'
filename = __filename
current_trace_error = null
in_prepare = 0

exports.empty_frame = '---------------------------------------------'
exports.async_trace_limit = 10

format_location = (frame) ->
  return 'native' if frame.isNative()
  return 'eval at ' + frame.getEvalOrigin() if frame.isEval()
  
  file = frame.getFileName()
  line = frame.getLineNumber()
  column = frame.getColumnNumber()
  
  return 'unknown source' unless file?
  column = if column? then ':' + column else ''
  line = if line? then ':' + line else ''
  
  file + line + column

format_method = (frame) ->
  function_name = frame.getFunctionName()
  
  unless frame.isToplevel() or frame.isConstructor()
    method = frame.getMethodName()
    type = frame.getTypeName()
    return "#{type}.#{method ? '<anonymous>'}" unless function_name?
    return "#{type}.#{function_name}" if method is function_name
    "#{type}.#{function_name} [as #{method}]"
  
  return "new #{function_name ? '<anonymous>'}" if frame.isConstructor()
  return function_name if function_name?
  null

exports.format_stack_frame = (frame) ->
  return exports.empty_frame if frame.getFileName() is exports.empty_frame
  
  method = format_method(frame)
  location = format_location(frame)
  
  return "    at #{location}" unless method?
  "    at #{method} (#{location})"

exports.format_stack = (err, frames) ->
  lines = []
  try
    lines.push(err.toString())
  catch e
    console.log 'Caught error in longjohn. Please report this to matt.insler@gmail.com.'
  lines.push(frames.map(exports.format_stack_frame)...)
  lines.join('\n')

create_callsite = (location) ->
  Object.create {
    getFileName: -> location
    getLineNumber: -> null
    getFunctionName: -> null
    getTypeName: -> null
    getMethodName: -> null
    getColumnNumber: -> null
    isNative: -> null
  }

prepareStackTrace = (error, structured_stack_trace) ->
  ++in_prepare
  
  unless error.__cached_trace__?
    error.__cached_trace__ = structured_stack_trace.filter (f) -> f.getFileName() isnt filename
    error.__previous__ = current_trace_error if !error.__previous__? and in_prepare is 1
    
    if error.__previous__?
      previous_stack = error.__previous__.stack
      if previous_stack?.length > 0
        error.__cached_trace__.push(create_callsite(exports.empty_frame))
        error.__cached_trace__.push(previous_stack...)
  
  --in_prepare
  
  return error.__cached_trace__ if in_prepare > 0
  exports.format_stack(error, error.__cached_trace__)

limit_frames = (stack) ->
  return if exports.async_trace_limit <= 0
  
  count = exports.async_trace_limit - 1
  previous = stack
  
  while previous? and count > 1
    previous = previous.__previous__
    --count
  delete previous.__previous__ if previous?

ERROR_ID = 1

call_stack_location = ->
  orig = Error.prepareStackTrace
  Error.prepareStackTrace = (x, stack) -> stack
  err = new Error()
  Error.captureStackTrace(err, arguments.callee)
  stack = err.stack
  Error.prepareStackTrace = orig
  
  "#{stack[2].getFunctionName()} (#{stack[2].getFileName()}:#{stack[2].getLineNumber()})"

wrap_callback = (callback, location) ->
  trace_error = new Error()
  trace_error.id = ERROR_ID++
  trace_error.location = call_stack_location()
  trace_error.__location__ = location
  trace_error.__previous__ = current_trace_error
  trace_error.__trace_count__ = if current_trace_error? then current_trace_error.__trace_count__ + 1 else 1
  
  limit_frames(trace_error)
  
  new_callback = ->
    current_trace_error = trace_error
    # Clear trace_error variable from the closure, so it can potentially be garbage collected.
    trace_error = null

    try
      callback.apply(this, arguments)
    catch e
      # Ensure we're formatting the Error in longjohn
      e.stack
      throw e
    finally
      current_trace_error = null
  
  new_callback.__original_callback__ = callback
  new_callback



_on = EventEmitter.prototype.on
_addListener = EventEmitter.prototype.addListener
_once = EventEmitter.prototype.once
_removeListener = EventEmitter.prototype.removeListener
_listeners = EventEmitter.prototype.listeners

EventEmitter.prototype.addListener = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap_callback(callback, 'EventEmitter.addListener')
  _addListener.apply(this, args)

EventEmitter.prototype.on = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap_callback(callback, 'EventEmitter.on')
  _on.apply(this, args)

EventEmitter.prototype.once = (event, callback) ->
  args = Array::slice.call(arguments)
  args[1] = wrap_callback(callback, 'EventEmitter.once')
  _once.apply(this, args)

EventEmitter.prototype.removeListener = (event, callback) ->
  find_listener = (callback) =>
    is_callback = (val) ->
      val.__original_callback__ is callback or
      val.__original_callback__?.listener?.__original_callback__ is callback or
      val.listener?.__original_callback__ is callback
    
    return null unless @_events?[event]?
    return @_events[event] if is_callback(@_events[event])
    
    if Array.isArray(@_events[event])
      listeners = @_events[event] ? []
      for l in listeners
        return l if is_callback(l)
    
    null
  
  listener = find_listener(callback)
  return @ unless listener? and typeof listener is 'function'
  _removeListener.call(@, event, listener)

EventEmitter.prototype.listeners = (event) ->
  listeners = _listeners.call(this, event)
  unwrapped = []
  for l in listeners
    if l.__original_callback__
      unwrapped.push l.__original_callback__
    else
      unwrapped.push l
  return unwrapped

_nextTick = process.nextTick

process.nextTick = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap_callback(callback, 'process.nextTick')
  _nextTick.apply(this, args)


__nextDomainTick = process._nextDomainTick

process._nextDomainTick = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap_callback(callback, 'process.nextDomainTick')
  __nextDomainTick.apply(this, args)


_setTimeout = global.setTimeout
_setInterval = global.setInterval

global.setTimeout = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap_callback(callback, 'global.setTimeout')
  _setTimeout.apply(this, args)

global.setInterval = (callback) ->
  args = Array::slice.call(arguments)
  args[0] = wrap_callback(callback, 'global.setInterval')
  _setInterval.apply(this, args)

if global.setImmediate?
  _setImmediate = global.setImmediate

  global.setImmediate = (callback) ->
    args = Array::slice.call(arguments)
    args[0] = wrap_callback(callback, 'global.setImmediate')
    _setImmediate.apply(this, args)

Error.prepareStackTrace = prepareStackTrace
