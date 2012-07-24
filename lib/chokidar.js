var events = require('events');

var FSWatcher = function() {
  // mock API
  this.watchedPaths_ = [];

  this.add = function(path) {
    this.watchedPaths_.push(path);
  };
};

FSWatcher.prototype = new events.EventEmitter();


// PUBLIC
exports.FSWatcher = FSWatcher;
