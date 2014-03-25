// adapted from this crazy gist: https://gist.github.com/jed/982883
// note: this is not cryptographically secure, but it should do well enough
// for most applciations.  If you want a more secure UUID, you can use another
// module to generate one.
(function (global) {

  global.uuid = { v4: b };
  
  function b(
    a                  // placeholder
  ){
    return a           // if the placeholder was passed, return
      ? (              // a random number from 0 to 15
        a ^            // unless b is 8,
        Math.random()  // in which case
        * 16           // a random number from
        >> a/4         // 8 to 11
        ).toString(16) // in hexadecimal
      : (              // or otherwise a concatenated string:
        [1e7] +        // 10000000 +
        -1e3 +         // -1000 +
        -4e3 +         // -4000 +
        -8e3 +         // -80000000 +
        -1e11          // -100000000000,
        ).replace(     // replacing
          /[018]/g,    // zeroes, ones, and eights with
          b            // random hex digits
        )
  }

})(this);