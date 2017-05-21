module Buffer

%include C "idris_buffer.h"

||| A buffer is a pointer to a sized, unstructured, mutable chunk of memory
export
record Buffer where
  constructor MkBuffer
  ||| Raw bytes, as a pointer to a block of memory
  rawdata : ManagedPtr -- let Idris run time manage the memory
  ||| Cached size of block
  buf_size : Int
  ||| Next location to read/write (e.g. when reading from file)
  location : Int

||| Create a new buffer 'size' bytes long. Returns 'Nothing' if allocation
||| fails
export
newBuffer : (size : Int) -> IO (Maybe Buffer)
newBuffer size = do bptr <- foreign FFI_C "idris_newBuffer" (Int -> IO Ptr)
                                    size
                    bad <- nullPtr bptr
                    if bad then pure Nothing
                           else pure (Just (MkBuffer (prim__registerPtr bptr (size + 8)) size 0))

||| Reset the 'next location' pointer of the buffer to 0.
||| The 'next location' pointer gives the location for the next file read/write
||| so resetting this means you can write it again
export
resetBuffer : Buffer -> Buffer
resetBuffer buf = record { location = 0 } buf

||| Return the space available in the buffer
export
rawSize : Buffer -> IO Int
rawSize b = foreign FFI_C "idris_getBufferSize" (ManagedPtr -> IO Int) (rawdata b)

export
size : Buffer -> Int
size b = buf_size b

||| Set the byte at position 'loc' to 'val'.
||| Does nothing if the location is outside the bounds of the buffer
export
setByte : Buffer -> (loc : Int) -> (val : Bits8) -> IO ()
setByte b loc val
    = foreign FFI_C "idris_setBufferByte" (ManagedPtr -> Int -> Bits8 -> IO ())
              (rawdata b) loc val


||| Return the value at the given location in the buffer
export
getByte : Buffer -> (loc : Int) -> IO Bits8
getByte b loc
    = foreign FFI_C "idris_getBufferByte" (ManagedPtr -> Int -> IO Bits8)
              (rawdata b) loc

export
bufferData : Buffer -> IO (List Bits8)
bufferData b = do let len = size b
                  unpackTo [] len
  where unpackTo : List Bits8 -> Int -> IO (List Bits8)
        unpackTo acc 0 = pure acc
        unpackTo acc loc = do val <- getByte b (loc - 1)
                              unpackTo (val :: acc)
                                       (assert_smaller loc (loc - 1))

export
getData : Buffer -> IO Ptr
getData b =
  let dataPtr = prim__ptrOffset (prim__asPtr (rawdata b)) 0 in
    prim_peekPtr dataPtr 0

export
getDataFor : Buffer -> IO Ptr
getDataFor b = foreign FFI_C "my_getBufferDataPtr"
                       (ManagedPtr -> IO Ptr) (rawdata b)
