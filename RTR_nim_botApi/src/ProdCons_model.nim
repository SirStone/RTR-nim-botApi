import random, locks, system, os

const bufferSize = 100

type
  RingList[T] = object
    data: array[bufferSize, T]
    writeIndex: int
    readIndex: int
    count: int
    lock: Lock
    notFull: Cond
    notEmpty: Cond

proc put[T](r: var RingList[T], item: T) =
  acquire(r.lock)
  while r.count == bufferSize:
    wait(r.notFull, r.lock)
  r.data[r.writeIndex] = item
  r.writeIndex = (r.writeIndex + 1) mod bufferSize
  r.count += 1
  echo "how mainy items in buffer:", r.count
  signal(r.notEmpty)
  release(r.lock)

proc get[T](r: var RingList[T]): T =
  acquire(r.lock)
  while r.count == 0:
    wait(r.notEmpty, r.lock)
  let item = r.data[r.readIndex]
  r.readIndex = (r.readIndex + 1) mod bufferSize
  r.count -= 1
  signal(r.notFull)
  release(r.lock)
  return item

var ringList: RingList[int]
initLock(ringList.lock)
initCond(ringList.notFull)
initCond(ringList.notEmpty)

proc producer() =
  while true:
    let num = rand(100)
    put(ringList, num)
    sleep(1)
    # echo "Produced:", num
  put(ringList, -1)  # indicating end of production

proc consumer() =
  var num: int
  while true:
    num = get(ringList)
    if num == -1:  # end of production
      echo "Consumed:", num
      break

var workerP, workerC: Thread[void]
createThread(workerP, producer)
createThread(workerC, consumer)

joinThreads(workerP, workerC)