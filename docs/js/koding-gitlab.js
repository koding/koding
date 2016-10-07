(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var YOUTUBE_EMBED, blocksWithKoding, blocksWithoutKoding, descVideoSection, mainVideoLink, mainVideoSection, playVideo, playingVideo, ready, resetVideoStatus, scroll, scrollLink, trySection, tryVideo, withKodingLink, withoutKodingLink;

scroll = require('scroll');

blocksWithKoding = document.getElementById('blocksVideoWithKoding');

blocksWithoutKoding = document.getElementById('blocksVideoWithoutKoding');

tryVideo = document.getElementById('tryVideo');

descVideoSection = document.getElementById('descriptionSection');

mainVideoSection = document.getElementById('MainVideo-FullScreen');

trySection = document.getElementById('Try-Koding-and-GitLab');

mainVideoLink = document.getElementById('mainVideoPlayButton');

withKodingLink = document.getElementById('oneClickWatch');

withoutKodingLink = document.getElementById('lifeSucksWatch');

scrollLink = document.getElementById('scrollDown');

YOUTUBE_EMBED = '<iframe width="1120" height="630" src="https://www.youtube.com/embed/T59sN8Bsqxs" frameborder="0" allowfullscreen></iframe>';

playingVideo = false;

resetVideoStatus = function(vid, otherVid, section) {
  vid.pause();
  playingVideo = null;
  section.classList.remove('out');
  otherVid.style.display = 'block';
  descVideoSection.classList.remove('withKoding');
  return descVideoSection.classList.remove('withoutKoding');
};

playVideo = function(event, name) {
  var otherVid, section, vid;
  if (name === 'withKoding') {
    vid = blocksWithKoding;
    otherVid = blocksWithoutKoding;
  } else {
    vid = blocksWithoutKoding;
    otherVid = blocksWithKoding;
  }
  section = descVideoSection;
  section.classList.add(name);
  event.stopPropagation();
  event.preventDefault();
  if (playingVideo) {
    if (playingVideo[0] === vid) {
      return resetVideoStatus.apply(this, playingVideo);
    } else {
      resetVideoStatus.apply(this, playingVideo);
      section.classList.add(name);
    }
  }
  otherVid.style.display = 'none';
  section.classList.add('out');
  vid.play();
  return playingVideo = [vid, otherVid, section];
};

ready = function() {
  var playedOnce;
  scrollLink.addEventListener('click', function() {
    var whereToScroll;
    whereToScroll = trySection.getBoundingClientRect().top + document.body.scrollTop;
    return scroll.top(document.body, whereToScroll, {
      duration: 300
    });
  });
  withKodingLink.addEventListener('click', function(event) {
    return playVideo(event, 'withKoding');
  });
  blocksWithKoding.addEventListener('ended', function() {
    blocksWithKoding.currentTime = 0;
    return resetVideoStatus(blocksWithKoding, blocksWithoutKoding, descVideoSection);
  });
  withoutKodingLink.addEventListener('click', function(event) {
    return playVideo(event, 'withoutKoding');
  });
  blocksWithoutKoding.addEventListener('ended', function() {
    blocksWithoutKoding.currentTime = 0;
    return resetVideoStatus(blocksWithoutKoding, blocksWithKoding, descVideoSection);
  });
  mainVideoLink.addEventListener('click', function(event) {
    mainVideoSection.innerHTML = YOUTUBE_EMBED;
    mainVideoSection.classList.add('in');
    return mainVideoSection.classList.add('fade');
  });
  mainVideoSection.addEventListener('click', function(event) {
    mainVideoSection.innerHTML = '';
    mainVideoSection.classList.remove('fade');
    return setTimeout(function() {
      return mainVideoSection.classList.remove('in');
    }, 500);
  });
  playedOnce = false;
  return window.onscroll = function() {
    var vidTopOffset;
    vidTopOffset = trySection.getBoundingClientRect().top;
    if (vidTopOffset < 100 && !playedOnce) {
      trySection.classList.add('focus');
      return setTimeout(function() {
        return tryVideo.play();
      }, 500);
    }
  };
};

ready();

},{"scroll":4}],2:[function(require,module,exports){
(function (global){
if (typeof window !== "undefined") {
    module.exports = window;
} else if (typeof global !== "undefined") {
    module.exports = global;
} else if (typeof self !== "undefined"){
    module.exports = self;
} else {
    module.exports = {};
}

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{}],3:[function(require,module,exports){
var global = require('global')

/**
 * `requestAnimationFrame()`
 */

var request = global.requestAnimationFrame
  || global.webkitRequestAnimationFrame
  || global.mozRequestAnimationFrame
  || fallback

var prev = +new Date
function fallback (fn) {
  var curr = +new Date
  var ms = Math.max(0, 16 - (curr - prev))
  var req = setTimeout(fn, ms)
  return prev = curr, req
}

/**
 * `cancelAnimationFrame()`
 */

var cancel = global.cancelAnimationFrame
  || global.webkitCancelAnimationFrame
  || global.mozCancelAnimationFrame
  || clearTimeout

if (Function.prototype.bind) {
  request = request.bind(global)
  cancel = cancel.bind(global)
}

exports = module.exports = request
exports.cancel = cancel

},{"global":2}],4:[function(require,module,exports){
var raf = require('rafl')

function scroll (prop, element, to, options, callback) {
  var start = +new Date
  var from = element[prop]
  var cancelled = false

  var ease = inOutSine
  var duration = 350

  if (typeof options === 'function') {
    callback = options
  }
  else {
    options = options || {}
    ease = options.ease || ease
    duration = options.duration || duration
    callback = callback || function () {}
  }

  if (from === to) {
    return callback(
      new Error('Element already at target scroll position'),
      element[prop]
    )
  }

  function cancel () {
    cancelled = true
  }

  function animate (timestamp) {
    if (cancelled) {
      return callback(
        new Error('Scroll cancelled'),
        element[prop]
      )
    }

    var now = +new Date
    var time = Math.min(1, ((now - start) / duration))
    var eased = ease(time)

    element[prop] = (eased * (to - from)) + from

    time < 1 ?
      raf(animate) :
      callback(null, element[prop])
  }

  raf(animate)

  return cancel
}

function inOutSine (n) {
  return .5 * (1 - Math.cos(Math.PI * n));
}

module.exports = {
  top: function (element, to, options, callback) {
    return scroll('scrollTop', element, to, options, callback)
  },
  left: function (element, to, options, callback) {
    return scroll('scrollLeft', element, to, options, callback)
  }
}

},{"rafl":3}]},{},[1]);

(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){


},{}]},{},[1]);
