var util = require('util');
var EventEmitter = require('events').EventEmitter;


var ServerResponse = function() {
  var bodySent = false;

  this._headers = {};
  this._body = null;
  this._status = null;

  this._isFinished = function() {
    return this.headerSent && bodySent;
  };

  this.headerSent = false;

  this.setHeader = function(name, value) {
    if (this.headerSent) {
      throw new Error("Can't set headers after they are sent.");
    }

    this._headers[name] = value;
  };

  this.getHeader = function(name) {
    return this._headers[name];
  };

  this.removeHeader = function(name) {
    delete this._headers[name];
  };

  this.writeHead = function(status) {
    if (this.headerSent) {
      throw new Error("Can't render headers after they are sent to the client.");
    }

    this.headerSent = true;
    this._status = status;
  };

  this.write = function(content) {
    if (bodySent) {
      throw new Error("Can't write to already finished response.");
    }

    this._body = this._body ? this._body + content.toString() : content.toString();
  };

  this.end = function(content) {
    if (content) {
      this.write(content );
    }

    bodySent = true;
    this.emit('end');
  };
};

util.inherits(ServerResponse, EventEmitter);

var ServerRequest = function(url, headers) {
  this.url = url;
  this.headers = headers || {};

  this.getHeader = function(key) {
    return this.headers[key];
  };
};

util.inherits(ServerRequest, EventEmitter);


// PUBLIC stuff
exports.ServerResponse = ServerResponse;
exports.ServerRequest = ServerRequest;
