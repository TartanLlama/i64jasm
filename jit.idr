module Main

import Buffer

copyToBuffer : Buffer -> List Bits8 -> IO Buffer
copyToBuffer buf xs =
  do
    copyToBuffer' buf xs 0;
    pure buf

  where
    copyToBuffer' : Buffer -> List Bits8 -> Int -> IO()
    copyToBuffer' buf (x::xs) n =
      do
        setByte buf n x;
        copyToBuffer' buf xs (n+1)
    copyToBuffer' buf [] n = pure ()

toBuffer : List Bits8 -> IO (Maybe Buffer)
toBuffer chars =
  do
    buf <- newBuffer $ fromNat $ List.length chars
    case buf of
      Just buf => do
        buf <- copyToBuffer buf chars
        pure (Just buf)
      Nothing => pure Nothing

toByteList : Int -> List Int
toByteList i =
    [getByte i 0, getByte i 1, getByte i 2, getByte i 3]
  where
    getByte : Int -> Int -> Int
    getByte i n = prim__zextB8_Int $ prim__truncInt_B8 $ prim__lshrInt i (n*8)

helloBytes : Int -> List Bits8
helloBytes addr =
   map prim__truncInt_B8 chars
  where
    chars : List Int
    chars = [0xb8, 0x04, 0x00, 0x00, 0x00]
              ++ [0xbb, 0x01, 0x00, 0x00, 0x00]
              ++ (0xb9 :: toByteList addr)
              ++ [0xba, 0x0e, 0x00, 0x00, 0x00]
              ++ [0xcd, 0x80]
              ++ [0xc3]


{-helloWorld : Int -> IO (Maybe Buffer)
helloWorld addr = do
  buf <- newBuffer 34
  case buf of
    Just buf' =>
      do
        buf'' <- copyToBuffer buf' helloBytes
        pure $ Just buf''
    Nothing => pure Nothing-}

%include C "sys/mman.h"
%link C "memcpy.o"

allocJitBuffer : Int -> IO Ptr
allocJitBuffer n = foreign FFI_C "mmap"
                           (Ptr -> Int -> Int -> Int -> Int -> Int -> IO Ptr)
                           null n 7 flags (-1) 0
  where
    flags = 0x22

memcpy : Ptr -> Ptr -> Int -> IO Ptr
memcpy dest src n = foreign FFI_C "mymemcpy"
                           (Ptr -> Ptr -> Int -> IO Ptr)
                           dest src n

callJitBuffer : Ptr -> IO ()
callJitBuffer ptr = foreign FFI_C "%dynamic"
                            (Ptr -> IO ())
                            ptr

||| Create a buffer for a string with maximum length len
newString : (len : Int) -> IO Ptr
newString len = do ptr <- foreign FFI_C "idris_makeStringBuffer"
                                         (Int -> IO Ptr) len
                   pure ptr

||| Append a string to the end of a string buffer
addToString : Ptr -> String -> IO ()
addToString ptr str =
    foreign FFI_C "my_addToString" (Ptr -> String -> IO ())
            ptr str

asciz : String -> IO Ptr
asciz str = do
  ptr <- newString $ fromNat $ Strings.length str
  addToString ptr str
  ptr' <- prim_peekPtr ptr 0
  pure ptr'

%include C "memory.h"
%include C "ptr_to_int.h"

toInt : Ptr -> IO Int
toInt p = foreign FFI_C "ptr_to_int" (Ptr -> IO Int) p

main : IO ()
main = do
  textPtr <- asciz "Hello, world!"
  textPtr' <- toInt textPtr
  buf <- allocJitBuffer 128
  codeBuf <- toBuffer $ helloBytes textPtr'
  case codeBuf of
    Just codeBuf =>
      do
        dataPtr <- getDataFor codeBuf
        ptr <- memcpy buf dataPtr (size codeBuf)
        callJitBuffer ptr

    Nothing => pure ()
