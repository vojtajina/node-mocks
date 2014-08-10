var util = require('util');
var EventEmitter = require('events').EventEmitter;


var ServerResponse = function() {
  var bodySent = false;

  this._headers = {};
  this._body = null;
  this._statusCode = null;
  this._statusText = null;

  this._isFinished = function() {
    return this.headerSent && bodySent;
  };

  this.headerSent = false;

  this.setHeader = function(name, value) {
    if (this.headerSent) {
      throw new Error("Can't set headers after they are sent.");
    }

    this._headers[name.toLowerCase()] = value;
  };

  this.getHeader = function(name) {
    return this._headers[name];
  };

  this.removeHeader = function(name) {
    delete this._headers[name];
  };

  this.writeHead = function(status, reason, headers) {
    if (this.headerSent) {
      throw new Error("Can't render headers after they are sent to the client.");
    }

    if (typeof reason === 'object') {
      headers = reason;
      reason = undefined;
    }
    headers = headers || {};

    for(var name in headers) {
      this._headers[name.toLowerCase()] = headers[name];
    }

    this.headerSent = true;
    this._statusCode = status;
    this._statusText = reason;
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

  this.getDebugData = function() {
    return {
      status: {code: this._statusCode, text: this._statusText},
      header: this._headers,
      body: this._body
    };
  }
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
