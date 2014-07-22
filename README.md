gulp-webpack-config
==================

Gulp plugin to run webpack on a stream of config file and wrap the results in a vinyl file

```
gulp = require 'gulp'
webpack = require 'gulp-webpack-config'

HEADER = """
/*
  <%= file.path.split('/').splice(-1)[0] %> <%= pkg.version %>
  Copyright (c) 2013-#{(new Date()).getFullYear()} Your Name
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
*/\n
"""

gulp.task 'build', ->
  gulp.src('config/builds/library/**/*.webpack.config.coffee', {read: false, buffer: false})
    .pipe(webpack())
    .pipe(header(HEADER, {pkg: require('./package.json')}))
    .pipe(gulp.dest('.')
```

### Note

1. if you do not specify an output filename, it will infer it from the file passed using the following conventions:

- filename.js -> filename.js
- filename.config.js -> filename.js
- filename.webpack.config.js -> filename.js
- filename.webpack.config.coffee -> filename.js

### Options

1. pure (boolean) - false if you do not want to automatically delete the file after webpacking. Useful if you do not want a pure file-based approach.
