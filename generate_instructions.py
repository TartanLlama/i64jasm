import opcodes.x86_64 as x64

def operand_to_idris(op, name):
    map = {
        'al': '(R8 al)',
        'ax': '(R16 ax)',
        'eax': '(R32 eax)',        
        'rax': '(R64 rax)',
        'r8': '(R8 {})'.format(name),
        'r16': '(R16 {})'.format(name),
        'r32': '(R32 {})'.format(name),
        'r64': '(R62 {})'.format(name),
        'imm8': '(B8 {})'.format(name),
        'imm16': '(B16 {})'.format(name),
        'imm32': '(B32 {})'.format(name),
        'imm64': '(B64 {})'.format(name),
        'm8': '(B8 {})'.format(name),
        'm16': '(B16 {})'.format(name),
        'm32': '(B32 {})'.format(name),
        'm64': '(B64 {})'.format(name),
        'm128': '(B128 {})'.format(name),
        'mm': '(mm {})'.format(name),
        'xmm': '(xmm {})'.format(name),
        'xmm0': '(xmm0 {})'.format(name),
        'rel8': '(B8 {})'.format(name),
        'rel32': '(B32 {})'.format(name),

        'moffs32': '(B32 {})'.format(name),
        'moffs64': '(B64 {})'.format(name),

        'cl': 'cl',
        
        'k': 'k',
        'm': 'm',
        '1': '1',
        '3': '3',
        }

    if op in map:
        return map[op]

    return 'unknown'

def rex_to_idris(rex, operands):
    if rex == None:
        return 0

    if type(rex) == x64.Operand:
        return 0 #TODO fix
        
    return rex
        
instruction_set = x64.read_instruction_set()
out = open('instructions.idr', 'w')

for instr in instruction_set:
    if instr.name is not 'V':
        out.write('-- {}\n'.format(instr.summary))
        for form in instr.forms:
            out.write(instr.name.lower())

            for (i,operand) in enumerate(form.operands):
                idris_type = operand_to_idris(operand.type, chr(ord('a')+i))
                out.write(' {}'.format(idris_type))
                
            out.write(' = do\n')

            enc = form.encodings[0]
            
            for comp in enc.components:
                if type(comp) == x64.Prefix and comp.is_mandatory:
                    out.write('\temit [{}]'.format(hex(comp.byte)))
                    out.write(' --legacy prefix\n')

                if type(comp) == x64.REX and comp.is_mandatory:
                    byte = 64 #mandatory prefix
                    w = rex_to_idris(comp.W, form.operands)
                    r = rex_to_idris(comp.R, form.operands)
                    x = rex_to_idris(comp.X, form.operands)
                    b = rex_to_idris(comp.B, form.operands)

                    byte |= (w<<3) | (r<<2) | (x<<1) | (b<<0)
                    out.write('\temit [{}]'.format(hex(byte)))
                    out.write(' --REX prefix\n')

                if type(comp) == x64.Opcode:
                    #TODO addend
                    out.write('\temit [{}]'.format(hex(comp.byte)))
                    out.write(' --opcode\n')                    

                    

    

