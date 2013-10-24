# longjohn

Long stack traces for [node.js](http://nodejs.org/) with configurable call trace length

## Inspiration

I wrote this while trying to add [long-stack-traces](https://github.com/tlrobinson/long-stack-traces) to my server and realizing that there were issues with support of [EventEmitter::removeListener](http://nodejs.org/api/events.html#events_emitter_removelistener_event_listener).  The node HTTP Server will begin to leak callbacks and any of your own code that relies on removing listeners would not work as anticipated.

So what to do...  I stole the code and rewrote it.  I've added support for removeListener along with the ability to cut off the number of async calls the library will trace.  I hope you like it!

Please thank [tlrobinson](https://github.com/tlrobinson) for the initial implementation!

## Installation

Just npm install it!

```bash
$ npm install longjohn
```

## Usage

To use longjohn, require it in your code (probably in some initialization code).  That's all!

```javascript
require('longjohn');

// ... your code
```

## Options

#### Limit traced async calls

```javascript
longjohn.async_trace_limit = 5;   // defaults to 10
longjohn.async_trace_limit = -1;  // unlimited
```

#### Change callback frame text

```javascript
longjohn.empty_frame = 'ASYNC CALLBACK';  // defaults to '---------------------------------------------'
```
