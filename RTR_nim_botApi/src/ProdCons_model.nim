import std/[os, atomics]
import loony

type
  Message = ref object
    value: string

let fifo = newLoonyQueue[Message]()
var terminate: Atomic[bool]

proc producer() {.thread.} =
  for i in 1..10:
    let msg = Message(value: "Message " & $i)
    echo "Producing ", repr(msg)
    fifo.push msg

proc consumer() {.thread.} =
  while not terminate.load:
    let item = fifo.pop
    if not item.isNil:
      echo "Consumed: ", repr(item)

# Create worker threads
var producerThread, consumerThread: Thread[void]

# Start worker threads
createThread(producerThread, producer)
createThread(consumerThread, consumer)

joinThread(producerThread)
terminate.store(true)
joinThread(consumerThread)