var util = require('util');
var path = require('path');
var predictableNextTick = require('./util.js').predictableNextTick;


/**
 * @constructor
 * @param {boolean} isDirectory
 */
var Stats = function(isFile, mtime) {
  this.mtime = mtime;

  this.isDirectory = function() {
    return !isFile;
  };

  this.isFile = function() {
    return isFile;
  };
};


var File = function(mtime, content) {
  this.mtime = mtime;
  this.content = content || '';

  this.getStats = function() {
    return new Stats(true, new Date(this.mtime));
  };

  this.getBuffer = function() {
    return new Buffer(this.content);
  };
};


var Directory = function(mtime) {
  this.mtime = mtime;

  this.getStats = function() {
    return new Stats(false, new Date(this.mtime));
  };
};


/**
 * @constructor
 * @param {Object} structure
 */
var Mock = function(structure) {
  var watchers = {};
  var cwd = '/';

  // TODO(vojta): convert structure to contain only instances of File/Directory (not primitives)

  var getPointer = function(filepath, pointer) {
    var absPath = path.resolve(cwd, filepath);
    var parts = absPath.replace(/\\/g, '/').replace(/\/$/, '').split('/').slice(1);

    while (parts.length) {
      if (!pointer[parts[0]]) break;
      pointer = pointer[parts.shift()];
    }

    return parts.length ? null : pointer;
  };


  var validatePath = function(path) {
    if (path.charAt(0) !== '/') {
      throw new Error('Relative path not supported !');
    }
  };


  // public API
  this.stat = function(path, callback) {
    var statSync = this.statSync;

    predictableNextTick(function() {
      var stat = null;
      var error = null;

      try {
        stat = statSync(path);
      } catch(e) {
        error = e;
      }

      callback(error, stat);
    });
  };


  this.statSync = function(path) {
    validatePath(path);

    var pointer = getPointer(path, structure);

    if (!pointer) {
      var error = new Error('ENOENT, no such file or directory "' + path + '"');

      error.errno = 34;
      error.code = 'ENOENT';

      throw error;
    }

    return pointer instanceof File ? pointer.getStats() : new Stats(typeof pointer !== 'object');
  };


  this.readdir = function(path, callback) {
    validatePath(path);
    predictableNextTick(function() {
      var pointer = getPointer(path, structure);
      return pointer && typeof pointer === 'object' && !(pointer instanceof File) ?
             callback(null, Object.getOwnPropertyNames(pointer).sort()) : callback({});
    });
  };


  this.readdirSync = function(path, callback) {
    validatePath(path);

    var pointer = getPointer(path, structure);
    var error;

    if (!pointer) {
      error = new Error('ENOENT, no such file or directory "' + path + '"');
      error.errno = 34;
      error.code = 'ENOENT';

      throw error;
    }

    if(pointer instanceof File) {
      error = new Error('ENOTDIR, not a directory "' + path + '"');
      error.errno = 27;
      error.code = 'ENOTDIR';

      throw error;
    }

    return Object.keys(pointer);
  };


  this.mkdir = function(directory, callback) {
    var mkdirSync = this.mkdirSync;
    var error = null;

    predictableNextTick(function() {
      try {
        mkdirSync(directory);
      } catch (e) {
        error = e;
      }

      callback(error);
    });
  };


  this.mkdirSync = function(directory) {
    var pointer = getPointer(path.dirname(directory), structure);
    var baseName = path.basename(directory);

    if (pointer && typeof pointer === 'object' && !(pointer instanceof File)) {
      pointer[baseName] = {};
      return;
    }

    var error = new Error(util.format('ENOENT, mkdir "%s"', directory));
    error.code = 'ENOENT';
    error.errno = 34;

    throw error;
  };


  this.readFile = function(path, encoding, callback) {
    var readFileSync = this.readFileSync;
    callback = callback || encoding;

    predictableNextTick(function() {
      var data = null;
      var error = null;

      try {
        data = readFileSync(path);
      } catch(e) {
        error = e;
      }

      callback(error, data);
    });
  };


  this.readFileSync = function(path) {
    var pointer = getPointer(path, structure);
    var error;

    if (!pointer) {
      error = new Error(util.format('No such file or directory "%s"', path));
      error.code = 'ENOENT';

      throw error;
    }

    if (pointer instanceof File) {
      return pointer.getBuffer();
    }

    if (typeof pointer === 'object') {
      error = new Error('Illegal operation on directory');
      error.code = 'EISDIR';

      throw error;
    }

    return new Buffer('');
  };


  this.writeFile = function(filePath, content, callback) {
    predictableNextTick(function() {
      var pointer = getPointer(path.dirname(filePath), structure);
      var baseName = path.basename(filePath);

      if (pointer && typeof pointer === 'object' && !(pointer instanceof File)) {
        pointer[baseName] = new File(0, content);
        callback(null);
      } else {
        var error = new Error(util.format('Can not open "%s"', filePath));
        error.code = 'ENOENT';
        callback(error);
      }
    });
  };


  this.watchFile = function(path, options, callback) {
    callback = callback || options;
    watchers[path] = watchers[path] || [];
    watchers[path].push(callback);
  };


  this.exists = function(path, callback) {
    var existsSync = this.existsSync;

    predictableNextTick(function() {
      callback(existsSync(path));
    });
  };


  this.existsSync = function(path) {
    return getPointer(path, structure) != null;
  }


  // Mock API
  this._touchFile = function(path, mtime, content) {
    var pointer = getPointer(path, structure);
    var previous = pointer.getStats();

    // update the file
    if (typeof mtime !== 'undefined') pointer.mtime = mtime;
    if (typeof content !== 'undefined') pointer.content = content;

    var current = pointer.getStats();
    (watchers[path] || []).forEach(function(callback) {
      callback(current, previous);
    });
  };

  this._setCWD = function(path) {
    cwd = path;
  };
};


// PUBLIC stuff
exports.create = function(structure) {
  return new Mock(structure);
};

exports.file = function(mtime, content) {
  return new File(mtime, content);
};
