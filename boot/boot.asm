;; SOS Boot Loader
;; Author: Will Dignazio
;; Date: 06/18/2011
;; Rev.: 01/07/2012
;; Description:  
;; 	Boot sector code for the Atlas bootloader, loads the 
;; init program to initialize and set the rest of the 
;; environement. All in real mode, so it uses the BIOS
;; to read the init program from the disk. 
[BITS 16]
[global boot_load] 
[extern init]
[SECTION .boot]
boot_load:

  mov [bootdrv], dl		; set boot drv var
  mov si, bootstr
  call printxt

  cli					; have to stop ints for stack change
  mov ax, 0x9000	
  mov ss, ax			; Set stack segment to 9000
  mov sp, 0				; SS:SP(0)
  sti					; re-enable interrupts
  
  mov [bootdrv], dl		; make sure bootdrive is set 
  call initLoad			; Load the init program 
  mov si, attempt
  call printxt
  call init				; Call outide of the bootloader

;; Load Init
;;	- Loads the init program from the boot drive
;; 	- Uses all the registers
;;	- Returns error codes in ah
initLoad: 
  push ds
 .reset:
  mov ax, 0
  mov dl, [bootdrv]
  int 13h 				; Reset drive
  jc .reset
  pop ds
   
 .read:
  mov ax, 0x50			; Dump location	
  mov es, ax			; Set dump location offset
  mov bx, 0 		
  mov ah, 2				; Read func
  mov al, 2 			; Read 2  sectors (512 bytes x 2)
  mov cx, 2				; Cylinder to 0 (ch), and init sector to 2 (cl)
  mov dh, 0				; Head
  mov dl, [bootdrv]
  int 13h				; call read function bios interrupt
  jc .read				; If we are good, then don't try to read again

  cmp ah, 00
  je .ok				; if ah is 0, then int 13h went alright
  mov si, error
  call printxt
  mov al, ah			; The error code was in ah, now in al
  call print			; we want to print it out after the colon
  mov al, 0Dh		
  call print
  mov al, 0Ah
  call print
  mov si,wReboot	
  call printxt
  mov ah, 0				; Function 0
  int 16h				; Wait for keyboard press
  call warmreboot  
 .ok:
  mov dl, [bootdrv]
  retn

;; Warm Reboot 
;;	- Reboots the computer without fully turning it off
;;	- Resets pretty much everything
warmreboot:
  mov ax, 40h			; bios location
  mov ds, ax			; set data segment here
  mov word[72h], 1234h	; warm reboot val
  jmp 0ffffh:0			; jmp and execute

;; Print Character 
;; 	- print a single character to the terminal 
;; 	- move single character scancod to AL
print:
  mov ah, 0Eh			; Write Character and attribute at cursor position
  mov bh, 0				; page number 
  mov bl, 07h			; color (white)
  int 10h
  ret			

;; Print Text
;;	- print a series of charaters, a string or text, to the terminal.
;; 	- move the address of the text to si
;; 	- The first character must be startoftext char (STX)
;; 	- The final character must be endoftext char (ETX)
printxt:
  mov al, [si]		
  cmp al, 02h			; Compare to STX
  jne .error

 .print:
  inc si				; next character
  mov al, [si]		
  cmp al, 03h
  je .done
  call print		
  jmp .print
 .done:		
  ret

 .error: 
  mov si, notxt
  call printxt
  ret

wReboot db 0x02, 'PRESS ANY KEY TO REBOOT', 0x0A, 0x0D, 0x03
attempt db 0x02, 'Exiting the Bootloader...', 0x0A, 0x0D, 0x03
error db 0x02, 'AN ERROR HAS OCCURRED IN THE BOOTLOADER: ', 0x03
done db 0x02, 'Done.', 0x0A, 0x0D, 0x03
bootstr db 0x02,'Booting...', 0x0A, 0x0D, 0x03
notxt db 0x02, 'Error: Not a String',0x0A, 0x0D, 0x03
bootdrv db 0

times 510-($-$$) db 0		; Fill to end
dw 0xaa55					; Signature
EXIT:
