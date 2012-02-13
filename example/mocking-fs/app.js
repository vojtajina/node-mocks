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
