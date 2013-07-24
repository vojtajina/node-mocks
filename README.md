# Node Mocks [![Build Status](https://secure.travis-ci.org/vojtajina/node-mocks.png?branch=master)](http://travis-ci.org/vojtajina/node-mocks)

Set of mocks and utilities for easier unit testing with [Node.js].

See http://howtonode.org/testing-private-state-and-mocking-deps for better explanation.

## Prerequisites

* [Node.js]
* [NPM] (shipped with Node since 0.6.3)


## Installation

    sudo npm install -g mocks

    # or install in local folder
    npm install mocks


## Example

### Mocking a file system

````javascript
// during unit test - we inject mock file system instead of real fs
var fs = require('fs');

// even if this function is not public, we can test it directly
var filterOnlyExistingFiles = function(collection, done) {
  var filtered = [],
      waiting = 0;

  collection.forEach(function(file) {
    waiting++;
    fs.stat(file, function(err, stat) {
      if (!err && stat.isFile()) filtered.push(file);
      waiting--;
      if (!waiting) done(null, filtered);
    });
  });
};
````

````coffeescript
# simple unit test (jasmine syntax, coffescript)
describe 'app', ->
  mocks = require 'mocks'
  loadFile = mocks.loadFile
  app = done = null

  beforeEach ->
    done = jasmine.createSpy 'done'
    # load the file and inject fake fs module
    app = loadFile __dirname + '/app.js',
      fs: mocks.fs.create
        'bin':
          'run.sh': 1,
          'install.sh': 1
        'home':
          'some.js': 1,
          'another.txt': 1
        'one.js': 1,
        'two.js': 1,
        'three.js': 1


  it 'should return only existing files', ->
    done.andCallFake (err, filtered) ->
      expect(err).toBeFalsy()
      expect(filtered).toEqual ['/bin/run.sh']

    app.filterOnlyExistingFiles ['/bin/run.sh', '/non.txt'], done
    waitsFor -> done.callCount

  it 'should ignore directories', ->
    done.andCallFake (err, filtered) ->
      expect(filtered).toEqual ['/bin/run.sh', '/home/some.js']

    app.filterOnlyExistingFiles ['/bin/run.sh', '/home', '/home/some.js'], done
    waitsFor -> done.callCount
````

### Faking randomness
Non-blocking I/O operations can return in random order. Let's say you read a content of two files (asynchronously). There is no guarantee, that you get the content in right order. That's fine, but we want to test our code, whether it can handle such a situation and still work properly. In that case, you can use `predictableNextTick`, which process callbacks depending on given pattern.

````coffeescript

  it 'should preserve order', ->
    done.andCallFake (err, filtered) ->
      expect(filtered).toEqual ['/one.js', '/two.js', '/three.js']

    app.filterOnlyExistingFiles ['/one.js', '/two.js', '/three.js'], done
    waitsFor -> done.callCount
````
This test will always pass. That's cool, as we like to see tests passing. The bad thing is, that it does not work in production, with real file system, as it might return in different order...
So, we need to test, whether our app works even when the `fs` returns in random order. Having randomness in unit tests is not good habit, as it leads to flaky tests.
Let's change the previous unit test to this:

````coffeescript
  it 'should preserve order', ->
    done.andCallFake (err, filtered) ->
      expect(filtered).toEqual ['/one.js', '/two.js', '/three.js']

    mocks.predictableNextTick.pattern = [2, 0, 1]
    app.filterOnlyExistingFiles ['/one.js', '/two.js', '/three.js'], done
    waitsFor -> done.callCount
````
Now, the unit test fails, because our fake file system calls back in different order. Note, it's not random, as you explicitly specified the pattern (2, 0, 1), so it the fake fs will consistently call back in this order: /three.js, /one.js, two.js.


## API
Currently supported API is only very small part of real [Node's API]. Basically I only implemented methods I need for testing [Testacular].

I will keep adding more and of course if anyone wants to help - pull requests are more than welcomed.

### [fs](http://nodejs.org/api/fs.html)

- stat(path, callback)
- readdir(path, callback)
- readFile(path [, encoding], callback)
- readFileSync(path)
- watchFile(path [, options], callback)
- _touchFile(path, mtime, content) *

### [http](http://nodejs.org/api/http.html)

- http.ServerResponse
- http.ServerRequest

### [glob](https://github.com/isaacs/node-glob)


### loadFile(path [, mocks] [, globals])
### predictableNextTick(fn)
### predictableNextTick.pattern

[Node.js]: http://nodejs.org/
[NPM]: http://npmjs.org/
[Node's API]: http://nodejs.org/docs/latest/api/index.html
[Testacular]: https://github.com/vojtajina/testacular
