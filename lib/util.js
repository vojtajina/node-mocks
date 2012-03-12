var vm = require('vm');
var fs = require('fs');
var path = require('path');

var nextTickQueue = [];
var nextTickRegistered = false;

var nextTickHandler = function() {
  var pattern = predictableNextTick.pattern;
  var queue = nextTickQueue;

  nextTickRegistered = false;
  nextTickQueue = [];

  var base = 0;
  while (base < queue.length) {
    pattern.forEach(function(i) {
      var index = base + i;
      if (queue[index]) {
        try {
          queue[index]();
          queue[index] = null;
        } catch(e) {
          // filter only fns that still needs to be executed
          // just in the case someone will handle the exception
          queue[index] = null;
          var stillNeedToBeExec = queue.filter(function(fn) {
            return fn;
          });

          // re-register handler if there are more fns to execute
          if (stillNeedToBeExec.length) {
            nextTickQueue = stillNeedToBeExec.concat(nextTickQueue);

            if (!nextTickRegistered) {
              process.nextTick(nextTickHandler);
              nextTickHandlerRegistered = true;
            }
          }

          throw e;
        }
      }
    });
    base += pattern.length;
  }
};

var predictableNextTick = function(callback) {
  nextTickQueue.push(callback);

  if (!nextTickRegistered) {
    process.nextTick(nextTickHandler);
    nextTickRegistered = true;
  }
};

predictableNextTick.pattern = [0];

/**
 * Helper for unit testing:
 * - load module with mocked dependencies
 * - allow accessing private state of the module
 *
 * @param {string} path Absolute path to module (file to load)
 * @param {Object=} mocks Hash of mocked dependencies
 * @param {Object=} globals Hash of globals ()
 */
var loadFile = function(filePath, mocks, globals) {
  mocks = mocks || {};

  // this is necessary to allow relative path modules within loaded file
  // i.e. requiring ./some inside file /a/b.js needs to be resolved to /a/some
  var resolveModule = function(module) {
    if (module.charAt(0) !== '.') return module;
    return path.resolve(path.dirname(filePath), module);
  };

  var exports = {};
  var context = {
    require: function(name) {
      return mocks[name] || require(resolveModule(name));
    },
    __dirname: path.dirname(filePath),
    __filename: filePath,
    process: process,
    console: console,
    exports: exports,
    module: {
      exports: exports
    }
  };

  Object.getOwnPropertyNames(globals || {}).forEach(function(name) {
    context[name] = globals[name];
  });

  vm.runInNewContext(fs.readFileSync(filePath), context);
  return context;
};


// PUBLIC stuff
exports.loadFile = loadFile;
exports.predictableNextTick = predictableNextTick;
exports.predictableNextTickPattern = [0];
