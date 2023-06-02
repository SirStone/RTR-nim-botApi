import std/locks

const
  BufferSize = 10

type
  RingList*[T] = object
    buffer: array[0..BufferSize - 1, T]
    count: int
    writeIndex: int
    readIndex: int
    lock: Lock
    notEmpty: Cond
    notFull: Cond

var
  ringList: RingList[string]
  producerThreads: array[0..0, Thread[RingList[string]]]
  consumerThreads: array[0..0, Thread[RingList[string]]]

proc producer(r: var RingList[string]) {.thread.} =
  for i in 1..10:
    acquire(r.lock)
    while r.count >= BufferSize:
      r.notFull.wait(r.lock)
    r.buffer[r.writeIndex] = "Item " & $i
    r.count += 1
    echo "Produced: ", r.buffer[r.writeIndex]
    r.writeIndex = (r.writeIndex + 1) mod BufferSize
    r.notEmpty.signal()
    release(r.lock)

proc consumer(r: var RingList[string]) {.thread.} =
  for i in 1..10:
    acquire(r.lock)
    while r.count <= 0:
      r.notEmpty.wait(r.lock)
    let item = r.buffer[r.readIndex]
    r.count -= 1
    echo "Consumed: ", item
    r.readIndex = (r.readIndex + 1) mod BufferSize
    r.notFull.signal()
    release(r.lock)

initLock(ringList.lock)
initCond(ringList.notEmpty)
initCond(ringList.notFull)

createThread(producerThreads[0], proc () {.thread, nimcall.} = producer, ringList)
createThread(consumerThreads[0], proc () {.thread, nimcall.} = consumer, ringList)

joinThread(producerThreads[0])
joinThread(consumerThreads[0])

deinitCond(ringList.notFull)
deinitCond(ringList.notEmpty)
deinitLock(ringList.lock)
