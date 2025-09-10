DATA79      EQU     0FFE8H
CNTR79      EQU     0FFEAH
IR_WR       EQU     0FFC1H
IR_RD       EQU     0FFC3H
DR_WR       EQU     0FFC5H

MAXLEN      EQU     16

CODE        SEGMENT
            ASSUME CS:CODE, DS:CODE
            ORG 0

START:      
            MOV SP, 4000H
            MOV AX, CS
            MOV DS, AX

            ; ??? ?????? "message:"
            MOV AH, 00H
            CALL IRWR
            LEA SI, MSG

MAIN_LOOP:
RESTART_PROGRAM:
            CALL CLEAR_LCD
            MOV AH, 80H
            CALL IRWR
            LEA SI, MSG
PRINT_MSG:  
            LODSB
            OR AL, AL
            JZ INPUT_START
            CALL OUTL
            JMP PRINT_MSG

INPUT_START:
            MOV AH, 0C0H       
            CALL IRWR
            XOR SI, SI  

NEXT_CHAR:  
            CALL READ_KEY

            CMP AL, '+'         
            JE ENCRYPT_PROCESS
	    
	    CMP AL, '-'
	    JE RESTART_PROGRAM

            CMP AL, ' '         
            JE NEXT_CHAR

            CMP AL, '0'
            JB VALID_CHAR
            CMP AL, '9'
            JBE NEXT_CHAR       

VALID_CHAR:
            CALL OUTL
            MOV [INPUT_BUFFER + SI], AL
            INC SI
            CMP SI, MAXLEN
            JB NEXT_CHAR        
            JMP ENCRYPT_PROCESS

ENCRYPT_PROCESS:
            CALL CLEAR_LCD

            ; ????? "enc:"
            MOV AH, 80H
            CALL IRWR
            LEA SI, ENC_LABEL
PRINT_ENC:  
            LODSB
            OR AL, AL
            JZ DO_ENCRYPT
            CALL OUTL
            JMP PRINT_ENC

DO_ENCRYPT:
            XOR DI, DI          ; ???? ?? ENC_BUFFER
            XOR SI, SI

ENC_LOOP:
            MOV AL, [INPUT_BUFFER + SI]
            CMP AL, 0
            JE PRINT_DEC
            CALL ENCRYPT_CHAR
            MOV [ENC_BUFFER + DI], AL
            CALL OUTL
            INC SI
            INC DI
            JMP ENC_LOOP

PRINT_DEC:
            ; ????? ??????
            MOV AH, 0C0H
            CALL IRWR
            LEA SI, DEC_LABEL
PRINT_DEC_LABEL:
            LODSB
            OR AL, AL
            JZ DO_DECRYPT
            CALL OUTL
            JMP PRINT_DEC_LABEL

DO_DECRYPT:
            XOR SI, SI

DEC_LOOP:
            MOV AL, [ENC_BUFFER + SI]
            CMP AL, 0
            JE Reset
            CALL DECRYPT_CHAR
            CALL OUTL
            INC SI
            JMP DEC_LOOP 
            
Reset:      CALL READ_KEY

            CMP AL, '-'         
            JNE  SKIP_RESTART_PROGRAM
            JMP  RESTART_PROGRAM
            

            SKIP_RESTART_PROGRAM:
	    JMP Reset

DONE:
            JMP $

; ===============================
; ????? ????? ?? ???????
READ_KEY:
    ; ?????? ?????
    MOV DX, CNTR79
WAIT_KEY:
    IN AL, DX
    TEST AL, 7
    JZ WAIT_KEY

    ; ????? ??????
    MOV DX, DATA79
    IN AL, DX

    ; ????? ?????? ??? ??? ???????? ????         
    MOV BX, OFFSET KEYMAP
    XLAT                
    RET 
    
; ???? ????? ?????? ??????? ??? ???? ASCII
KEYMAP  DB  '0123456789ABCDEF.,-+:R'

; ===============================
; ????? ??? ??? ??????
OUTL:
            CALL BUSY
            MOV DX, DR_WR
            OUT DX, AL
            RET

; ===============================
; ??????? ??? Instruction Register
IRWR:
            CALL BUSY
            MOV DX, IR_WR
            MOV AL, AH
            OUT DX, AL
            RET

; ===============================
; ?????? ?? ?? ?????? ??? ??????
BUSY:
            PUSH AX
            MOV DX, IR_RD
BUSY_LOOP:  IN AL, DX
            TEST AL, 80H
            JNZ BUSY_LOOP
            POP AX
            RET

; ===============================
; ??? ??????
CLEAR_LCD:
            MOV AH, 01H
            CALL IRWR
            MOV AH, 80H
            CALL IRWR
            RET

; ===============================
; ???????
ENCRYPT_CHAR:
            PUSH BX
            MOV BX, OFFSET ENC_TABLE
            MOV DL, AL
            SUB DL, 'A'
            JB INVALID
            CMP DL, 25
            JA INVALID
            XOR DH, DH
            ADD BX, DX
            MOV AL, [BX]
            JMP EXIT_ENC
INVALID:
            MOV AL, '?'
EXIT_ENC:
            POP BX
            RET

; ===============================
; ?? ???????
DECRYPT_CHAR:
            PUSH BX
            MOV BX, OFFSET DEC_TABLE
            MOV DL, AL
            SUB DL, 'a'
            JB INVALID_DEC
            CMP DL, 25
            JA INVALID_DEC
            XOR DH, DH
            ADD BX, DX
            MOV AL, [BX]
            JMP EXIT_DEC
INVALID_DEC:
            MOV AL, '?'
EXIT_DEC:
            POP BX
            RET

; ===============================
; ????????
MSG         DB 'message:',0
ENC_LABEL   DB 'enc:',0
DEC_LABEL   DB 'dec:',0

INPUT_BUFFER DB MAXLEN DUP(0)
ENC_BUFFER   DB MAXLEN DUP(0)

ENC_TABLE    DB 'qwertyuiopasdfghjklzxcvbnm'  ; ???? ??????? (a?s, b?u, ...)
DEC_TABLE    DB 'kxvmcnophqrszyijadlegwbuft'        ; ???? ?? ??????? (??? ENC_TABLE)

CODE        ENDS
            END START
