import locks, os

const bufferSize = 100

type
  RingBuffer*[T] = object
    data*: array[bufferSize, T]
    writeIndex*: int
    readIndex*: int
    count*: int
    lock*: Lock
    notFull*: Cond
    notEmpty*: Cond

proc put*[T](r: var RingBuffer[T], item: T) =
  acquire(r.lock)
  while r.count == bufferSize:
    wait(r.notFull, r.lock)
  r.data[r.writeIndex] = item
  r.writeIndex = (r.writeIndex + 1) mod bufferSize
  r.count += 1
  signal(r.notEmpty)
  release(r.lock)

proc get*[T](r: var RingBuffer[T]): T =
  acquire(r.lock)
  while r.count == 0:
    wait(r.notEmpty, r.lock)
  let item = r.data[r.readIndex]
  r.readIndex = (r.readIndex + 1) mod bufferSize
  r.count -= 1
  signal(r.notFull)
  release(r.lock)
  return item
