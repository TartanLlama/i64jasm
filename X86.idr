module X86

import Control.Monad.State

%access export

data Reg
  = RAX  -- Accumulator
  | RCX  -- Counter (Loop counters)
  | RDX  -- Data
  | RBX  -- Base / General Purpose
  | RSP  -- Current stack pointer
  | RBP  -- Previous Stack Frame Link
  | RSI  -- Source Index Pointer
  | RDI  -- Destination Index Pointer

data Val
  = B8 Bits8
  | B16 Bits16
  | B32 Bits32
  | B64 Bits64
  | R Reg


rax : Val
rax = R RAX

rcx : Val
rcx = R RCX

rdx : Val
rdx = R RDX

rbx : Val
rbx = R RBX

rsp : Val
rsp = R RSP

rbp : Val
rbp = R RBP

rsi : Val
rsi = R RSI

rdi : Val
rdi = R RDI

public export
record JIT where
  constructor MkJIT
  bin : List Bits8
  memptr : Ptr

initJIT : JIT
initJIT = MkJIT [] null

public export
X86 : Type -> Type
X86 a = StateT JIT Identity a

getJIT : X86 a -> JIT
getJIT x = snd $ runState x $ initJIT

emit : List Bits8 -> X86 ()
emit i = modify $ record { bin $= (++ i) }

syscall : X86 ()
syscall = emit [0x0f, 0x05]

ret : X86 ()
ret = emit [0xc3]
