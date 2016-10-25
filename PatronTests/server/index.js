const restify = require('restify')

function slow (req, res, next) {
  setTimeout(() => {
    let body = { message: 'sorry, I\'m late' }
    res.send(body)
    next()
  }, 1000)
}

function hello (req, res, next) {
  let body = { message: 'hello, ' + req.params.name }
  res.send(body)
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

function invalid (req, res, next) {
  res.writeHead(200)
  res.write('meh')
  res.end()
}

function potus (req, res, next) {
  res.send([
    { name: 'Barack Obama', start: 2009, end: 2016 },
    { name: 'George W. Bush', start: 2001, end: 2009 },
    { name: 'Bill Clinton', start: 1993, end: 2001 }
  ])
  next()
}

const server = restify.createServer()

server.get('/hello/:name', hello)
server.head('/hello/:name', hello)

server.post('/echo', echo)
server.head('/echo', echo)

server.head('/slow', slow)
server.get('/slow', slow)

server.head('/invalid', invalid)
server.get('/invalid', invalid)

server.head('/potus', potus)
server.get('/potus', potus)

server.listen(8080, () => {
  console.log('%s listening at %s', server.name, server.url)
})
