   /* Copyright (C) 2008 The Android Open Source Project
    *
    * Licensed under the Apache License, Version 2.0 (the "License");
    * you may not use this file except in compliance with the License.
    * You may obtain a copy of the License at
    *
    * http://www.apache.org/licenses/LICENSE-2.0
    *
    * Unless required by applicable law or agreed to in writing, software
    * distributed under the License is distributed on an "AS IS" BASIS,
    * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    * See the License for the specific language governing permissions and
    * limitations under the License.
    */

   /*
    * File: binopD2addr.S
    *
    * Code: 32-bit "/2addr" integer divde operation. If "div"
    *       is set, the code returns the quotient, else it returns
    *       the remainder. Also, a divide-by-zero check is done.
    *
    * For: div-int/2addr, rem-int/2addr
    *
    * Description: Perform a binary operation on two sources registers
    *              and store the result in the first source register
    *
    * Format: B|A|op (12x)
    *
    * Syntax: op vA, vB
    */

%default {"div":"1"}
    movl        rINST, %ecx             # %ecx<- BA
    shr         $$4, %ecx               # %ecx<- B
    andl        $$15, rINST             # rINST<- A, to be used as dest
    movl        rINST, %eax             # %eax<- A
    GET_VREG    %ecx                    # %edx<- vB
    testl       %ecx, %ecx               # check for divide by zero
    GET_VREG    %eax                    # %eax<- vA
    jz          common_errDivideByZero  # handle divide by zero
    cmpl        $$-1, %ecx              # handle -1 special case divide error
    jnz         .L${opcode}_continue
    cmpl        $$0x80000000, %eax       # handle min int special case divide error
    je         .L${opcode}_break

.L${opcode}_continue:
    cdq                                 # sign-extend %eax to %edx
    idiv        %ecx                    # divide %edx:%eax by %ecx
     .if  $div
    FFETCH_ADV  1, %edx                 # %ecx<- next instruction hi; fetch, advance
    SET_VREG    %eax rINST              # vAA<- %eax (quotient)
    FGETOP_JMP  1, %edx                 # jump to next instruction; getop, jmp
    .else
    FFETCH_ADV  1, %eax                 # %ecx<- next instruction hi; fetch, advance
    SET_VREG    %edx rINST              # vAA<- %edx (remainder)
    FGETOP_JMP  1, %eax                 # jump to next instruction; getop, jmp
    .endif

%break
.L${opcode}_break:
    FFETCH_ADV  1, %edx                 # %ecx<- next instruction hi; fetch, advance
    .if  $div
    movl        $$0x80000000, (rFP, rINST, 4) # vAA<- min int
    .else
    movl        $$0, (rFP, rINST, 4)    # vAA<- 0
    .endif
    FGETOP_JMP  1, %edx                 # jump to next instruction; getop, jmp

