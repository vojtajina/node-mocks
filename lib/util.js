var vm = require('vm');
var fs = require('fs');
var path = require('path');

var nextTickQueue = [];
var nextTickRegistered = false;
var pointerBase = 0;
var pointerInPattern = 0;


var reset = function() {
  nextTickRegistered = false;
  nextTickQueue.length = 0;
  pointerBase = 0;
  pointerInPattern = 0;
  predictableNextTick.pattern = [0];
};


var nextTickHandler = function() {
  var pattern = predictableNextTick.pattern;

  while (pointerBase < nextTickQueue.length) {
    while (pointerInPattern < pattern.length) {
      var index = pointerBase + pattern[pointerInPattern];

      if (nextTickQueue[index]) {
        try {
          nextTickQueue[index]();
          nextTickQueue[index] = null;
        } catch(e) {
          nextTickQueue[index] = null;

          // just in the case someone will handle the exception
          if (nextTickQueue.some(function(fn) { return fn; })) {
            process.nextTick(nextTickHandler);
          } else {
            reset();
          }

          throw e;
        }
      } else {
        // fill skipped holes, so that predictableNextTick() won't push into these holes
        while (nextTickQueue.length < index + 1) {
          nextTickQueue.push(null);
        }
      }
      pointerInPattern++;
    }
    pointerInPattern = 0;
    pointerBase += pattern.length;
  }

  reset();
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
 * @param {boolean} mockNested If true, mock even nested requires. Default to false
 */
var loadFile = function(filePath, mocks, globals, mockNested) {
  mocks = mocks || {};
  globals = globals || {};

  filePath = path.normalize(filePath);

  if (filePath.substr(-3) !== '.js') {
    filePath += '.js';
  }

  var exports = {};
  var context = {
    require: function(name) {
      // TODO(vojta): solve loading "localy installed" modules
      if (mocks.hasOwnProperty(name)) {
        return mocks[name];
      }

      // this is necessary to allow relative path modules within loaded file
      // i.e. requiring ./some inside file /a/b.js needs to be resolved to /a/some
      if (name.charAt(0) !== '.') {
        return require(name);
      }

      var absolutePath = path.resolve(path.dirname(filePath), name);

      if (mockNested) {
        return loadFile(absolutePath, mocks, globals, mockNested).module.exports;
      }

      return require(absolutePath);
    },
    __dirname: path.dirname(filePath),
    __filename: filePath,
    Buffer: Buffer,
    setTimeout: setTimeout,
    setInterval: setInterval,
    clearTimeout: clearTimeout,
    clearInterval: clearInterval,
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

  vm.runInNewContext(fs.readFileSync(filePath), context, filePath);

  return context;
};


// PUBLIC stuff
exports.loadFile = loadFile;
exports.predictableNextTick = predictableNextTick;
