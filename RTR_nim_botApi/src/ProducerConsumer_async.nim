# Producer-Consumer implemented with the asyncdispatch library
# https://nim-lang.org/docs/asyncdispatch.html
import asyncdispatch, sugar, random

var queue: seq[string] = @[]
var finished = false

proc producer() {.async.} =
  var i:int = 0
  while not finished:
    let item = "item" & $i
    # echo "producing", item
    queue = item & queue
    i += 1
    await sleepAsync(rand(10..100))
  echo "produced ",$i," items"

proc consumer(number:int) {.async.} =
  var i:int = 0
  while not finished:
    if queue.len > 0:
      discard queue.pop()
      i += 1
      # echo "consuming ", popped
    await sleepAsync(rand(10..100))
  echo "consumer ",number," consumed ",$i," items"

proc main() {.async.} =
  echo "starting producer 1"
  asyncCheck producer()

  echo "starting consumer 1"
  asyncCheck consumer(1)
  
  echo "starting consumer 2"
  asyncCheck consumer(2)

  echo "starting consumer 3"
  asyncCheck consumer(3)

  for i in 0..10:
    echo $(10-i)
    waitFor sleepAsync(1000)
  echo "finished"
  finished = true
  waitFor sleepAsync(2000)
waitFor main()