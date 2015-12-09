var restify = require('restify')

function hello (req, res, next) {
  res.send('hello ' + req.params.name)
  next()
}

function echo (req, res, next) {
  var buf = ''
  function read () {
    var chunk
    while ((chunk = req.read()) !== null) {
      buf += chunk
    }
  }
  function onend () {
    req.removeListener('readable', read)
    req.removeListener('end', onend)
    res.send(JSON.parse(buf))
    next()
  }
  req.on('readable', read)
  req.on('end', onend)
}

var server = restify.createServer()

server.get('/hello/:name', hello)
server.head('/hello/:name', hello)
server.post('/echo', echo)
server.head('/echo', echo)

server.listen(8080, function() {
  console.log('%s listening at %s', server.name, server.url)
})
