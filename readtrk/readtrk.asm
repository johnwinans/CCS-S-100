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


; Manually step the head in and out and dump a track on request
;
; s       select drive 2 (manual table is backward)
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
DIS1    EQU     0f1afh          ; hexdump from DE to HL


        ORG     1000H

        ld      hl,prompt
        call    prtwa
cmdloop:
        call    prstat
        call    CONI

        cp      'x'             ; exit application
;        ret     z
        jp      z,0f000h        ; cold-start the MOSS monitor

        ld      hl,cmdloop      ; put a return address in the stack for tail-calls
        push    hl

        cp      's'             ; select the drive
        jp      z,select        ; tail-call
        cp      ' '             ; un-select the drive (motor off, etc.)
        jp      z,unselect

        cp      '.'             ; step in
        jp      z,stepin        ; tail-call
        cp      ','             ; step out
        jp      z,stepout       ; tail-call

        cp      'r'             ; restore (seek to track 0)
        jp      z,restore       ; tail-call

        cp      'd'             ; read the current track into RAM at 2000h
        jp      z,readtrk

        cp      'p'             ; dump the begining of the track read
        jp      z,dumpit

        ret                     ; fix the stack & go back to cmdloop

prompt: defb    'Disk inspector',0dh,0ah|80h


;**************************************************************************
; Dump the first KB of the track-read buffer.
;**************************************************************************
RTBUFF  EQU     2000h
dumpit:
        ld      hl,RTBUFF
        ld      de,23ffh
        call    DIS1
        ld      hl,crlf
        jp      prtwa           ; tail-call


;**************************************************************************
; Read and dump a track
;**************************************************************************
readtrk:

; Note: One entire 3.5" DD track is about 6.5KB

RTLEN   EQU     8*1024
;RTLEN   EQU     2*1024
;RTLEN   EQU     4*256

        di                      ; make sure nothing will interrupt this

;        ld      a,0a2h          ; auto-wait, mini, motor-on, ds2, single-D
        ld      a,0e2h          ; auto-wait, mini, motor-on, ds2, double-D
        out     (DCTRL1),a

        ; select side 0
        ld      a,040h
        out     (DCTRL2),a

        ; zero out our target buffer and then some
        ld      hl,RTBUFF
        ld      (hl),0
        ld      de,RTBUFF+1
        ld      bc,RTLEN-1+100h
        ldir

        ld      bc,DDATA        ; count=256, port=DDATA
        ld      hl,RTBUFF       ; target address to read into

        ; NOTE: the auto_wait mode is terminated when INTRQ is asserted
        ; This will read d*256 bytes. Anything after the INTRQ will be garbage.
        ld      d,RTLEN/256

        ; dden readtrk command
        ld      a,0e4h          ; include delay for good measure
        out     (DCMD),a
rdloop:
if 1
        inir
        inir
        inir
        inir                    ; 1K

        inir
        inir
        inir
        inir                    ; 2K

        inir
        inir
        inir
        inir                    ; 3K

        inir
        inir
        inir
        inir                    ; 4K

        inir
        inir
        inir
        inir                    ; 5K

        inir
        inir
        inir
        inir                    ; 6K

        inir
        inir
        inir
        inir                    ; 7K
else

        ; read a track-load of data in a loop
        inir
if 1
        ; this logic is faster and will end after a known number of inir instructions
        dec     d
        jp      nz,rdloop
else
        ; this logic runs slower but could end earlier (or become an endless loop)
        in      a,(DSTAT1)
        rrca                   ; move the INTRQ bit into cy flag
        jp      nc,rdloop      ; if no INTRQ then keep reading
endif
endif


if 1
        ; read & dump the FDC status asap after the last inir instruction
        in      a,(DSTAT)       ; grab status exatly wnen ending
        ld      b,a
        in      a,(DSTAT1)
        ld      c,a
        push    bc
        ld      hl,prs1
        call    prtwa

        pop     bc
        push    bc
        ld      a,b
        call    HEX1
        ld      hl,prs4
        call    prtwa

        pop     bc
        ld      a,c
        call    HEX1
        ld      hl,crlf
        call    prtwa
endif

        ret
        


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
        ld      a,022h          ; mini, motor-on, ds2
        out     DCTRL1
        ret

unselect:
        ld      a,0
        out     DCTRL1
        ret

;**************************************************************************
; Step the currently selected disk head in (head is loaded)
;**************************************************************************
stepin:
        ld      a,058h          ; step in, update trk reg, rate=0
;        ld      a,050h          ; step in, update trk reg, rate=0
        out     DCMD
        jp      waitdone
        

;**************************************************************************
; Step the currently selected disk head in (head is loaded)
;**************************************************************************
stepout:
        ld      a,078h          ; step out, update trk reg, rate=0
;        ld      a,070h          ; step out, update trk reg, rate=0
        out     DCMD
        jp      waitdone

;**************************************************************************
; Move the head out to track 0
;**************************************************************************
restore:
        ld      a,8             ; restore, load the head, fastest step rate=0 (3msec)
;        ld      a,0             ; restore, do not load the head, step rate=0 (3msec)
        out     DCMD

waitdone:
        in      DSTAT1
        rar
        jr      nc,waitdone
        in      DSTAT
        and     a,0fch          ; 0 = no error 
        ret

;**************************************************************************
; A version of the MOSS PRTWA function that does not send crap in MSB. 
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
