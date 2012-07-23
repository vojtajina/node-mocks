var predictableNextTick = require('./util').predictableNextTick;


// Trivial mock for https://github.com/isaacs/node-glob
// It uses predictableNextTick, so that you can simulate different order of callbacks
//
// Creates new instance of glob
exports.create = function(results) {
  return function(pattern, options, done) {
    var result = results[pattern];

    if (!result) {
      throw new Error('Unexpected glob for "' + pattern + '"!');
    }

    predictableNextTick(function() {
      done(null, result);
    });
  };
};
