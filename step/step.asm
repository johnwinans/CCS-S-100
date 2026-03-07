;****************************************************************************
;
;        Copyright (C) 2026 John Winans
;
;        This library is free software; you can redistribute it and/or
;        modify it under the terms of the GNU Lesser General Public
;        License as published by the Free Software Foundation; either
;        version 2.1 of the License, or (at your option) any later version.
;
;        This library is distributed in the hope that it will be useful,
;        but WITHOUT ANY WARRANTY; without even the implied warranty of
;        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;        Lesser General Public License for more details.
;
;        You should have received a copy of the GNU Lesser General Public
;        License along with this library; if not, write to the Free Software
;        Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
;        USA
;
; https://github.com/johnwinans/CCS-S-100/
;
;****************************************************************************


; Manually step the head in and out using key codes from
; the CPU serial port.
;
; s       select drive 3
; space   unselect drive
; r       restore (step to track 0)
; ,       step in
; .       step out


; CCS 2422 registers
;
DCMD    EQU     30h             ; 1793 command
DSTAT   EQU     30h             ; 1793 status
DTRK    EQU     31h             ; 1793 track
DSEC    EQU     32h             ; 1793 sector
DDATA   EQU     33h             ; 1793 data

DCTRL1  EQU     34h             ; control 1
DSTAT1  EQU     34h             ; status 1
DCTRL2  EQU     04h             ; control 2
DSTAT2  EQU     04h             ; status 2


; MOSS monitor entry points of interest
CONI    EQU     0f68fh          ; console input (strips parity bit)
CONO    EQU     0f600h          ; console output

HEX1    EQU     0f5e6h          ; print A in hex on console


        ORG     1000H

        ld      hl,prompt
        call    prtwa
cmdloop:
        call    prstat
        call    CONI

        cp      'x'             ; exit application
        ret     z

        ld      hl,cmdloop      ; put a return address in the stack for tail-calls
        push    hl

        cp      's'             ; select the drive
        jp      z,select
        cp      ' '             ; un-select the drive (motor off, etc.)
        jp      z,unselect

        cp      '.'             ; step in
        jp      z,stepin
        cp      ','             ; step out
        jp      z,stepout

        cp      'r'             ; restore (seek to track 0)
        jp      z,restore

        pop     hl              ; fix the stack
        jp      cmdloop


prompt: defb    'Disk stepperizer',0dh,0ah|80h


;**************************************************************************
; Dump the status of the CCS 2422 card regs & 1793 regs.
;**************************************************************************
prstat:
        ld      hl,prs1
        call    prtwa
        in      DSTAT
        call    HEX1

        ld      hl,prs2
        call    prtwa
        in      DTRK
        call    HEX1

        ld      hl,prs3
        call    prtwa
        in      DSEC
        call    HEX1

        ld      hl,prs4
        call    prtwa
        in      DSTAT1
        call    HEX1

        ld      hl,prs5
        call    prtwa
        in      DSTAT2
        call    HEX1

        ld      hl,crlf
        jp      prtwa           ; tail-call

prs1:   dc     'stat:'
prs2:   dc     ' trk:'
prs3:   dc     ' sec:'
prs4:   dc     ' st1:'
prs5:   dc     ' st2:'
crlf:   db      0dh,0ah|80h


;**************************************************************************
; Select drive B, turn on the motor, set MINI mode (5.25")
;**************************************************************************
select:
        ld      a,022h          ; mini, motor-on, ds3
        out     DCTRL1
        ret

unselect:
        ld      a,0
        out     DCTRL1
        ret

;**************************************************************************
; Step the currently selected disk head in (head is NOT loaded)
;**************************************************************************
stepin:
        ld      a,058h          ; step in, update trk reg, fast
        out     DCMD
        jp      waitdone
        

;**************************************************************************
;**************************************************************************
stepout:
        ld      a,078h          ; step out, update trk reg, fast
        out     DCMD
        jp      waitdone

;**************************************************************************
; Move the head out to track 0
;**************************************************************************
restore:
;        ld      a,8             ; restore, load the head, fastest step rate (3msec)
        ld      a,0             ; restore, do not load the head, fastest step rate (3msec)
        out     DCMD

waitdone:
        in      DSTAT1
        rar
        jr      nc,waitdone
        in      DSTAT
        and     a,0fch          ; 0 = no error 
        ret


;**************************************************************************
; A 5% less sucky version of the MOSS PRTWA function.
; HL = string to print
; clobbers AF, HL, BC
;**************************************************************************
prtwa:
        ld      a,(hl)
        and     07fh            ; lose the MSB
        ld      c,a
        call    CONO
        ld      a,(hl)
        rlca
        ret     c               ; if MSB was set, we are done
        inc     hl
        jp      prtwa
