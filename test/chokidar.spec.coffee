#==============================================================================
# chokidar.js module
#==============================================================================
describe 'chokidar', ->
  chokidar = require '../lib/chokidar'
  watcher = null

  beforeEach ->
    watcher = new chokidar.FSWatcher

  it 'should store watched paths', ->
    watcher.add 'first.js'
    watcher.add ['/some/a.js', '/other/file.js']

    expect(watcher.watchedPaths_).toContain 'first.js', '/some/a.js', '/other/file.js'


  it 'should be event emitter', ->
    spy = jasmine.createSpy 'onAdd'
    watcher.on 'add', spy

    watcher.emit 'add'
    expect(spy).toHaveBeenCalled()
