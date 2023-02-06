; FWAV para la Flashjacks.
;
; Ultima version: 19-01-2022
;
;
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;Constantes del entorno.

; IDE registers:

IDE_BANK	equ	#4104
IDE_DATA	equ	#7C00
IDE_STATUS	equ	#7E07
IDE_CMD		equ	#7E07
IDE_ERROR	equ	#7E01
IDE_FEAT	equ	#7E01
IDE_SECCNT	equ	#7E02
IDE_LBALOW	equ	#7E03
IDE_LBAMID	equ	#7E04
IDE_LBAHIGH	equ	#7E05
IDE_HEAD	equ	#7E06
IDE_DEVCTRL	equ	#7E0E	;Device control register. Reset IDE por bit 2.
FJ_TIMER1	equ	#7E0D	;Temporizador de 100khz(100uSeg.) por registro. Decrece de 1 en 1 hasta llegar a 00h.

FJ_CLUSH_FB	equ	#7E2D	;Byte alto cluster archivo Flashboy.
FJ_CLUSL_FB	equ	#7E2E	;Byte bajo cluster archivo Flashboy
FLAGS_FB	equ	#7E2F	;Flags info Flashboy. (0,0,0,0,0,0,0,AccessRAM). "7..0"
FJ_TAM3_FB	equ	#7E30	;Byte alto3 tamaño archivo Flashboy.
FJ_TAM2_FB	equ	#7E31	;Byte alto2 tamaño archivo Flashboy.
FJ_TAM1_FB	equ	#7E32	;Byte alto1 tamaño archivo Flashboy.
FJ_TAM0_FB	equ	#7E33	;Byte bajo tamaño archivo Flashboy.
FJ_JOY_1	equ	#7E34	;Registro de salida Joy_Status1
FJ_JOY_2	equ	#7E35	;Registro de salida Joy_Status2
FJ_JOY_3	equ	#7E36	;Registro de salida Joy_Status3
FJ_JOY_4	equ	#7E37	;Registro de salida Joy_Status4
CAS_PARAM	equ	#7E40	;Registro parámetros del Cassette.
ROLLWAVS	equ	#7E41	;Registro parámetros del ADPCM. Valor RollWavs.
TIPOMUSICWAV	equ	#7E42	;Registro parámetros del ADPCM. Valor TipoMusicWav.
DIRCOMPAREH	equ	#7E43	;Registro parámetros del ADPCM. Valor DirRamCompareH.
DIRCOMPAREL	equ	#7E44	;Registro parámetros del ADPCM. Valor DirRamCompareL.
VALUERAM	equ	#7E45	;Registro parámetros del ADPCM. Valor ValueRam.
MUTESCC		equ	#7E46	;Registro parámetros del ADPCM. Valor MuteSCC.
MUTEFM		equ	#7E47	;Registro parámetros del ADPCM. Valor MuteFM.

; Bits in the status register

BSY	equ	7	;Busy
DRDY	equ	6	;Device ready
DF	equ	5	;Device fault
DRQ	equ	3	;Data request
ERR	equ	0	;Error

M_BSY	equ	(1 SHL BSY)
M_DRDY	equ	(1 SHL DRDY)
M_DF	equ	(1 SHL DF)
M_DRQ	equ	(1 SHL DRQ)
M_ERR	equ	(1 SHL ERR)

; Bits in the device control register register

SRST	equ	2	;Software reset
M_SRST	equ	(1 SHL SRST)

; Standard BIOS and work area entries
CLS	equ	000C3h
CHSNS	equ	0009Ch
KILBUF	equ	00156h
VDP	equ	0F3DFh

; Varios
CALSLT  equ     0001Ch
BDOS	equ	00005h
RDSLT	equ	0000Ch
WRSLT	equ	00014h
ENASLT	equ	00024h
FCB	equ	0005ch
DMA	equ	00080h
RSLREG	equ	00138h
SNSMAT	equ	00141h
RAMAD1	equ	0f342h
RAMAD2	equ	0f343h
LOCATE	equ	0f3DCh
CHGET	equ	0009fh
POSIT	equ	000C6h
MNROM	equ	0FCC1h	; Main-ROM Slot number & Secondary slot flags table
DRVINV	equ	0FB22H	; Installed Disk-ROM

;Fin de las constantes del entorno.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Macros:

;-----------------------------------------------------------------------------
;
; Enable or disable the IDE registers

;Note that bank 7 (the driver code bank) must be kept switched
;Cuidado. Cuando se cambia de IDE ON a OFF y viceversa, el mapper permanece inalterado.
;Cuando está en IDE_OFF, la siguiente vez permite cambiar de mapper.
;Así que no hacer dos IDE_OFF seguidos ya que el segundo IDE_OFF atacará a la página del mapper con valor cero en este caso.


macro	IDE_ON
	ld	a,1
	ld	(IDE_BANK),a
endmacro

macro	IDE_OFF
	ld	a,0
	ld	(IDE_BANK),a
endmacro

;-----------------------------------------------------------------------------
;
; Comprobación de que la unidad y los datos SD están disponibles.
macro ideready

.iderready:	
	ld	a,(IDE_STATUS)
	bit	BSY,a
	jp	nz,.iderready ; Hace una comprobación al inicio y deja paso cuando la FLASHJACKS informa que puede continuar.
	ld	hl, IDE_DATA
endmacro


;-----------------------------------------------------------------------------
;
; Fin de las macros.
;
;------------------------------------------------------------------------------
	

;------------------------------------------------------------------------------
;
; bytes de opciones:
;
;  options:                            options2:
;
;      bit0 -> Play		           bit0 -> no usado
;      bit1 -> Stop	                   bit1 -> no usado
;      bit2 -> Pause			   bit2 -> no usado
;      bit3 -> Next		  	   bit3 -> no usado
;      bit4 -> Previous			   bit4 -> no usado
;      bit5 -> no usado			   bit5 -> no usado
;      bit6 -> no usado			   bit6 -> no usado
;      bit7 -> no usado	                   bit7 -> no usado
;
;------------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
; Programa principal:

	org	0100h

	jp	inicio

textointro:     
	db	"FWAV para Flashjacks ver 1.10", 13,10
	db	"Reproductor de audio para MSX", 13,10,13,10
	db	13,10,"$"

txtWAV:	
	db	"Cargando WAV...",13,10,"$"

txtLST:	
	db	"Cargando LST...",13,10,"$"

txtPLAY:
	db	"Ejecutando comando PLAY...",13,10,"$"

txtSTOP:
	db	"Ejecutando comando STOP...",13,10,"$"

txtPAUSE:
	db	"Ejecutando comando PAUSE...",13,10,"$"

txtNEXT:
	db	"Ejecutando comando NEXT...",13,10,"$"

txtPREV:
	db	"Ejecutando comando PREV...",13,10,"$"

txtBypass:	
	db	"Bypass activado en Motor ON.",13,10,"$"

txtEjec:	
	db	"Ejecutada linea ","$"

txtEjec2:	
	db	" correctamente...",13,10,"$"

txtEnter:
	db	13,10,"$"



textonot:
	db	"     FWAV para Flashjacks ver 1.1", 13,10
	db	"     Reproductor de audio para MSX",13,10
	db	13,10
	db	"Notas del autor:",13,10
	db	13,10	
	db	" FWAV es un sistema sintetizado para" ,13,10
	db	"cargar WAVs y ADPCM en general.",13,10
	db	13,10
	db	"Intenta reproducir fielmente el audio",13,10
	db	"en formato de tabla de ondas.",13,10
	db	"A su vez, se puede usar como  ",13,10
	db	"reproductor de musica en un MSX. ",13,10
	db	"Con el listado puedes sustituir las",13,10
	db	"canciones de tus juegos favoritos.",13,10
	db	13,10
	db	"                               AQUIJACKS",13,10
	db	#1A,"$"

textoini:
	db	"     FWAV para Flashjacks ver 1.1", 13,10
	db	"     Reproductor de audio para MSX",13,10
fintextoini:	db	13,10
	db	"Modo de uso: FWAV wavfile.wav",13,10
	db	"             FWAV listfile.lst",13,10
	db	"             FWAV [opciones]",13,10
	db	"Opciones:",13,10
	db	"/P -> Play",13,10
	db	"/S -> Stop",13,10
	db	"/T -> Pause",13,10
	db	"/N -> Next",13,10
	db	"/B -> Prev",13,10
	db	"/H -> Notas del autor",13,10
	db	13,10
	db	#1A,"$"

inicio:
	ld	sp, (#0006)
	ld	a, (DMA)	
	or	a	
	jp	nz, readline	;Si encuentra parámetros continua.

muestratexto:			;Sin parámetros muestra el texto explicativo y sale.
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	; Averigua si es MSX-DOS2.
	XOR	A
	LD	DE,#0402
	CALL	#FFCA
	OR	A
	JP	Z,error11	;Para comprobar si realmente tienes las tablas.

	; Saca el texto de ayuda.
	ld	de, textoini	;Fija el puntero en el texto de ayuda.
	ld	c, 9
	call	BDOS		;Imprime por pantalla el texto.
	rst	0		;Salida al MSXDOS.

notastexto:			; Muestra el texto de notas del autor.
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	; Averigua si es MSX-DOS2.
	XOR	A
	LD	DE,#0402
	CALL	#FFCA
	OR	A
	JP	Z,error11	;Para comprobar si realmente tienes las tablas.

	; Saca el texto de ayuda.
	ld	de, textonot	;Fija el puntero en el texto de notas.
	ld	c, 9
	call	BDOS		;Imprime por pantalla el texto.
	rst	0		;Salida al MSXDOS.

readline:
	xor	a		
	ld	hl, #0082	;Extrae parametros de la linea de comandos.
	ld	de, filename
	call	saltaspacio	;Salta todos los espacios encontrados.
	jp	c, muestratexto ;Si no hay nombre de archivo ejecuta salir al MSXDOS.
	cp	"/"
	jp	z, leeoptions2  ;Si hay barra y no nombre de archivo ejecuta las opciones .

leefilename:	
	ldi
	ld	a, (hl)
	cp	" "
	jp	z, abre		;Va a operación de abrir si encuentra la barra espacio.
	jp	c, abre		;Va a operación de abrir archivo si no encuentra opciones. Programa secundario.
	jp	leefilename	;Bucle lectura nombre de archivo.

leeoptions2:
	call	saltaspacio	;Salta todos los espacios encontrados.
	ld	a, (hl)
	cp	"/"
	jp	nz, muestratexto;Si no encuentra una barra muestra el texto de opciones y fin.
	inc	hl
	ld	a, (hl)
	cp	" "
	jp	z, muestratexto
	jp	c, muestratexto ;Si es una barra con un espacio muestra el texto de opciones y fin.
	or	#20		;Pasa de si es mayusculas o minusculas.
	cp	"h"		
	jp	z, notastexto	;Si es una h saca las notas y el acerca de.
	ld	b, %1		;Selecciona la marca del bit a guardar.
	cp	"p"		
	jp	z, setoption3	;Si es una p guarda el valor en variale options
	ld	b, %10		;Selecciona la marca del bit a guardar.
	cp	"s"		
	jp	z, setoption3	;Si es una s guarda el valor en variale options
	ld	b, %100		;Selecciona la marca del bit a guardar.
	cp	"t"		
	jp	z, setoption3	;Si es una t guarda el valor en variale options
	ld	b, %1000	;Selecciona la marca del bit a guardar.
	cp	"n"		
	jp	z, setoption3	;Si es una n guarda el valor en variale options
	ld	b, %10000	;Selecciona la marca del bit a guardar.
	cp	"b"		
	jp	z, setoption3	;Si es una b guarda el valor en variale options
		
	jp	muestratexto	;Si es cualquier otra opción muestra el texto de opciones y fin.

;Fin del programa principal.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------	
;Subprocesos del programa principal:

;Almacena variable en options y salta a ejecutar las opciones.
setoption3:			
	ld	a, (options)
	or	b
	ld	(options), a
	inc	hl
	jp	abre_void	;Vuelve al bucle principal.

;Fin de los subprocesos del programa principal.
;-----------------------------------------------------------------------------


; Fin del programa principal.
;
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;
; Programa secundario. Fase de apertura del archivo ya con todas la opciones definidas.
; 

abre_void:
	ld	b, 0		;fichero.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	jp	searchslot

abre:	
	; Cargar archivo en FIB
	ld	de, filename	;Obtiene el File Info Block del
	ld	b, 0		;fichero.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	or	a
	jp	nz, error2	;Salta si error del archivo no se puede abrir.	

	; Proceso de comparar si son extensiones WAV o LST.
	ld	hl, filename
	ld	bc,8		; 8 carácteres.
C_Name3:	
	ld	a,(hl)		; Si no ha llegado al final lee el contenido siguiente por si es un punto.
	cp	02Eh		; Mira si hay un punto para tratarlo como extensión.	
	jp	z,C_Punto	; Salto por punto.
	inc	hl
	djnz	C_Name3		; Si no, va incrementado posiciones.

C_Punto:
	inc	hl		; Quitamos "."
	ld	a,(hl)			
	or	#20		; Pasa de si es mayusculas o minusculas.
	ld	(hl),a
	push	hl
	ld	de,Marca_LST	; Transfiere el Marca_LST a comparar.
	ld	b,3	

C_Verify:	
	ld	a,(de)		; Si no ha llegado al final lee el contenido siguiente por si es un punto.
	cp	(hl)		; Mira si hay un punto para tratarlo como extensión.	
	jp	nz,D_Punto	; Salto por comparación del byte incorrecto.
	inc	hl
	ld	a,(hl)			
	or	#20		; Pasa de si es mayusculas o minusculas.
	ld	(hl),a
	inc	de
	djnz	C_Verify	; Avanza de uno en uno.
	jp	C_Correct	; Si llega al final es que es correcto.

D_Punto:
	pop	hl		; Volvemos al inicio de la extensión.
	ld	de,Marca_WAV	; Transfiere el Marca_WAV a comparar.
	ld	b,3		

D_Verify:	
	ld	a,(de)		; Si no ha llegado al final lee el contenido siguiente por si es un punto.
	cp	(hl)		; Mira si hay un punto para tratarlo como extensión.	
	jp	nz,error3	 ;Salta si error del archivo no se puede abrir por no ser extensión LST ni WAV.	
	inc	hl
	ld	a,(hl)			
	or	#20		; Pasa de si es mayusculas o minusculas.
	ld	(hl),a
	inc	de
	djnz	D_Verify	; Avanza de uno en uno.
	jp	D_Correct	; Si llega al final es que es correcto.

C_Correct:
	pop	hl		; Quitamos de la pila el valor guardado.
	ld	a, 01		; Valor 1 corresponde a LST.
	ld	(TipoFile),a	; Lo guarda en la variable TipoFile.
	jp	searchslot
D_Correct:
	ld	a, 02		; Valor 2 corresponde a WAV.
	ld	(TipoFile),a	; Lo guarda en la variable TipoFile.

	
	;call	read_128B	;Lee los primeros 512bytes del archivo

; Busca la unidad Flashjacks en el sistema
searchslot:
	ld	a, (FIB+25)	;Averigua la unidad lógica actual.
	ld	b, a		
	ld	d, #FF		
	ld	c, #6A		
	call	BDOS
	
	ld	a, d
	dec	a		;Le resta 1 ya que el cero cuenta.
	ld	(unidad), a	;Guarda el número de unidad lógica de acceso.
		
	ld	hl, #FB21	;Mira el número de unidades conectado en la interfaz de disco 1.	
	cp	(hl)		
	jp	c, tipodisp	;Si coincide selecciona esta unidad y va a tipo de dispositivo.
	sub	a, (hl)
	inc	hl
	inc	hl		;Mira el número de unidades conectado en la interfaz de disco 2.
	cp	(hl)
	jp	c, tipodisp	;Si coincide selecciona esta unidad y va a tipo de dispositivo.
	sub	a, (hl)
	inc	hl
	inc	hl		;Mira el número de unidades conectado en la interfaz de disco 3.
	cp	(hl)
	jp	c, tipodisp	;Si coincide selecciona esta unidad y va a tipo de dispositivo.
	sub	a, (hl)
	inc	hl
	inc	hl		;Mira el número de unidades conectado en la interfaz de disco 4.
tipodisp:
	inc	hl		;Va al slot address disk de la unidad seleccionada.
	ld	(unidad), a	;Guarda el número de unidad lógica de acceso.
	ld	a, (hl)
	ld	(slotide), a	;Guarda en slotide la dirección de esa unidad.

	di
	ld	a,(slotide)	; Última petición a un subslot con FlashROM.
	ld	hl,4000h
	call	ENASLT

;Detección de la Flashjacks

	;ld	a,(slotide)	
	;ld	hl,5FFEh
	;ld	e,019h
	;call	WRSLT
	
	ld	a,019h		; Carga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	
	ld	a,076h
	ld	(5FFFh),a

	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.
	
	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,020h
	ld	(4340h),a	; Petición código de verificación de FlashJacks

	ld	b,16
	ld	hl,4100h	; Se ubica en la dirección 4100h (Es donde se encuentra la marca de 4bytes de FlashJacks)
RDID_BCL:
	ld	a,(hl)		; (HL) = Primer byte info FlashJacks
	cp	057h		; El primer byte debe ser 57h.
	jp	z,ID_2
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_2:	inc	hl
	ld	a,(hl)		; (HL) = Segundo byte info FlashJacks
	cp	071h		; El segundo byte debe ser 71h.
	jp	z,ID_3
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_3:	inc	hl
	ld	a,(hl)		; (HL) = Tercer byte info FlashJacks
	cp	098h		; El tercer byte debe ser 98h.
	jp	z,ID_4
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_4:	inc	hl
	ld	a,(hl)		; (HL) = Cuarto byte info FlashJacks
	cp	022h		; El cuarto byte debe ser 22h.

	jp	z,ID_OK		; Salta si da todo OK.
	
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	jp	error1		; Salta a error1 sin cierre de fichero(no lo ha abierto) si no es una Flashjacks.

ID_OK:	inc	hl
	ld	a,(hl)		; Al incrementar a 104h sale del modo info FlashJacks
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei
	
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.	

	ld	de, textointro	;Fija el puntero en el texto de intro.
	ld	c, 9
	call	BDOS

	; Comprueba primero si tiene la orden de play
	ld	a, (options)	;Si el bypass ha sido seleccionado salta sin abrir archivo..
	and	%1
	jp	nz, S_Play

	; Comprueba primero si tiene la orden de stop
	ld	a, (options)	;Si el bypass ha sido seleccionado salta sin abrir archivo..
	and	%10
	jp	nz, S_Stop

	; Comprueba primero si tiene la orden de pause
	ld	a, (options)	;Si el bypass ha sido seleccionado salta sin abrir archivo..
	and	%100
	jp	nz, S_Pause

	; Comprueba primero si tiene la orden de next
	ld	a, (options)	;Si el bypass ha sido seleccionado salta sin abrir archivo..
	and	%1000
	jp	nz, S_Next

	; Comprueba primero si tiene la orden de previous
	ld	a, (options)	;Si el bypass ha sido seleccionado salta sin abrir archivo..
	and	%10000
	jp	nz, S_Prev
	
	; Salta a gestión de archivo LST
	ld	a,(TipoFile)	; Recupera el tipo de archivo.
	cp	01h		; Tipo archivo LST.
	jp	z, S_LST	; Salta a proceso lectura en bloque de archivo LST.
	
	; Si no es nada de lo anterior, procede a la carga del archivo y reproducción.
	ld	de, txtWAV	;Fija el puntero en el texto de CargaWAV.
	ld	c, 9
	call	BDOS
	
	di
	IDE_ON
	ideready

	ld	a,050h		;Resetea estados de variables en FJ.
	ld	(IDE_CMD),a
	ideready

	; Cargar WAV en Flashjacks.	
	ld	a, (FIB+19)	;Top Cluster archivo abierto. Alto.
	ld	(FJ_CLUSH_FB),a	;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (FIB+20)	;Top Cluster archivo abierto. Bajo.
	ld	(FJ_CLUSL_FB),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (FIB+21)	;Tamaño archivo abierto. Alto3.
	ld	(FJ_TAM3_FB),a	;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (FIB+22)	;Tamaño archivo abierto. Alto2.
	ld	(FJ_TAM2_FB),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (FIB+23)	;Tamaño archivo abierto. Alto1.
	ld	(FJ_TAM1_FB),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (FIB+24)	;Tamaño archivo abierto. Bajo.
	ld	(FJ_TAM0_FB),a	;Ingresa el tamaño del archivo. Bajo. 

	ld	a,072h		;Carga WAV.
	ld	(IDE_CMD),a
	ideready		; Hasta que no termina la carga no avanza.

	ld	a,070h		;Le da al play.
	ld	(IDE_CMD),a
	ideready		; Hasta que no termina la carga no avanza.
	IDE_OFF
	ei

	ld	de, txtPLAY	;Fija el puntero en el texto de EjecutaPLAY.
	ld	c, 9
	call	BDOS

	jp	SalidaDos
	
S_Play:
	ld	de, txtPLAY	;Fija el puntero en el texto de EjecutaPLAY.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	ld	a,070h		;Le da al play.
	ld	(IDE_CMD),a
	ideready
	IDE_OFF
	ei
	jp	SalidaDos

S_Stop:
	ld	de, txtSTOP	;Fija el puntero en el texto de EjecutaSTOP.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	ld	a,071h		;Le da al stop.
	ld	(IDE_CMD),a
	ideready		; Hasta que no termina la carga no avanza.
	IDE_OFF
	ei
	jp	SalidaDos

S_Pause:
	ld	de, txtPAUSE	;Fija el puntero en el texto de EjecutaPAUSE.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	ld	a,073h		;Le da al pause.
	ld	(IDE_CMD),a
	ideready		; Hasta que no termina la carga no avanza.
	IDE_OFF
	ei
	jp	SalidaDos

S_Next:
	ld	de, txtNEXT	;Fija el puntero en el texto de EjecutaNEXT.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	ld	a,076h		;Le da al Next.
	ld	(IDE_CMD),a
	ideready		; Hasta que no termina la carga no avanza.
	IDE_OFF
	ei
	jp	SalidaDos

S_Prev:
	ld	de, txtPREV	;Fija el puntero en el texto de EjecutaPREVIOUS.
	ld	c, 9
	call	BDOS

	di
	IDE_ON
	ideready

	ld	a,077h		;Le da al Prev.
	ld	(IDE_CMD),a
	ideready		; Hasta que no termina la carga no avanza.
	IDE_OFF
	ei
	jp	SalidaDos

S_LST:
	; Zona de carga archivo tipo LST.
	ld	de, txtLST		;Fija el puntero en el texto de CargaLST.
	ld	c, 9
	call	BDOS

	call	read_FILE		;Llamada a transferir el contenido del archivo a buffer_FILE.

	call	reset_ADPCM		;Llamada a resetear todas las variables de comandos Flashjacks.

	call	Trans_buf		;Llamada a transferir las línea del buffer_FILE a comandos Flashjacks.

	jp	SalidaDos

;---------------------------------------------------------------------------
; Subprograma finalización del programa y salida estable al sistema

SalidaDos:

	di
	;IDE_ON
	;ideready
	
	;ld	a,050h		;Resetea estados de variables en FJ.
	;ld	(IDE_CMD),a

	;di
	;IDE_ON			;Activa la unidad IDE.
	;ideready

	;IDE_OFF
	
	ld	a,(RAMAD1)		;Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT			;Select Main-RAM at bank 4000h~7FFFh

	ei				; Activa interrupciones.

	xor	a			; Pone a cero el flag Z.
	ld	ix, KILBUF		; Petición de la rutina BIOS. En este caso KILBUF (Borra el buffer del teclado).
	ld	iy,(MNROM)		; BIOS slot
        call	CALSLT			; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.

	rst	0			;Salida al MSXDOS.

; Fin subprograma finalización del programa y salida estable al sistema
;---------------------------------------------------------------------------


;-----------------------------------------------------------------------------	
;Subproceso de quitar todos los slots y poner una ROM muerta para que te lance el BASIC. A posterior reset Flashjacks:

Reset:	di			; Desactiva interrupciones.
	ld	a,(slotide)	; Última petición a un subslot con FlashROM.
	ld	hl,04000h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,019h		; Carga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,076h
	ld	(5FFFh),a

	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.

	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,010h
	ld	(4340h),a	; Petición de carga externo de archivos.
	; Tipo mappers disponibles:
	; 00h y 7Fh  --  Instrucción ignorar carga externa.
	; 7Eh	     --  Carga externa con mapper AUTO (Lo selecciona FlashJacks con su autoanalisis)
	; 7Dh	     --	 Deja la Flashjacks vacia. Sin nada en los slots. 
	; 01h	     --  Carga externa con mapper KONAMI5
	; 02h	     --  Carga externa con mapper ASCII8K
	; 03h	     --  Carga externa con mapper KONAMI4
	; 04h	     --  Carga externa con mapper ASCII16K
	; 05h	     --  Carga externa con mapper SUNRISE IDE
	; 06h	     --  Carga externa con mapper SINFOX
	; 07h	     --  Carga externa con mapper ROM16K
	; 08h	     --  Carga externa con mapper ROM32K
	; 09h	     --  Carga externa con mapper ROM64K
	; 0Ah	     --  Carga externa con mapper RTYPE
	; 0Bh	     --  Carga externa con mapper ZEMINA6480
	; 0Ch	     --  Carga externa con mapper ZEMINA126
	; 0Dh	     --  Carga externa con mapper FMPAC
	;
	; Bit 7 del mapper:
	; 0	     --  Auto Expansor de Slots
	; 1	     --  Forzado Slot primario
	;
	;
	ld	a,7Dh		; Fuerza el vaciado de slots.
	ld	(4341h),a	; Petición de carga si no es 0.		
	ld	a,0ffh
	ld	(4348h),a	; Petición salida Autoselect.


; --- Reset por soft de la Flashjacks sincronizado con el reset del z80.
	

	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.
	
	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,030h
	ld	(4340h),a	; Petición código de reset de FlashJacks

	ld	b,16
	ld	hl,4666h	; Al leer en este momento la dirección x666h fuerza el reset por hardware de la flashjacks.
	ld	a,(hl)		; Despues de aquí, el msx tiene exactamente 0,1Segundos hasta que la Flashjacks deje de responder y haga el cambio de hardware.
	;Reset MSX ultrarápido
	rst	030h
	db	0
	dw	0000h
; Fin del Reset por soft de la Flashjacks sincronizado con el reset del z80.


;-----------------------------------------------------------------------------	
;Subproceso de salida del programa con mensaje de error:

txterror:	db	"Error: $"

error:	;Salida normal con mensaje de error.
	push	de		;Guarda el mensaje de error a mostrar.
	
	ei			;Activa interrupciones. Por si acaso se han quedado desactivadas.
	
	ld	a,(RAMAD1)	;Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT		;Select Main-RAM at bank 4000h~7FFFh

	ld	de, txterror	;Imprime por pantalla la palabrar Error.
	ld	c, #09
	call	BDOS

	pop	de		;Recupera e imprime por pantalla el mensaje del error.
	ld	c, #09
	call	BDOS

	ei			;Activa interrupciones. Por si acaso se han quedado desactivadas.
	rst	0		;Salida al MSXDOS.

error9: ;Salida cerrando archivo con mensaje de error:
	push	de

	ld	c, 10h		;Cierre del archivo.
	ld	de,FCB
	call	BDOS

	ei			;Activa interrupciones. Por si acaso se han quedado desactivadas.
	
	ld	a,(RAMAD1)	;Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT		;Select Main-RAM at bank 4000h~7FFFh

	ld	c, 9
	ld	de, txterror	;Imprime por pantalla la palabrar Error.
	call	BDOS

	pop	de		;Recupera e imprime por pantalla el mensaje del error.
	ld	c, #09
	call	BDOS

	rst	0		;Salida al MSXDOS.


;Mensajes de error:	
txterror1:	db	"FLASHJACKS no detectada!!",13,10,"$"
error1:
	ld	de, txterror1	;Error de Flashjacks no detectada.
	jp	error

txterror2:	db	"El archivo no se puede abrir!!",13,10,"$"
txterror3:	db	"El archivo no es compatible!!",13,10,"$"
txterror4:	db	"Archivo LST mas grande de 12kB!!",13,10,"$"
error2:
	ld	de, txterror2	;Error del archivo que no se puede abrir.
	jp	error

error2_:
	ld	de, txterror2	;Error del archivo que no se puede abrir cerrando archivo.
	jp	error9

error3:
	ld	de, txterror3	;Error del archivo que no se puede abrir cerrando archivo.
	jp	error

error4:
	pop	hl		; Mata el ret.
	ld	de, txterror4	;Error del archivo sobrepasa la capacidad de lectura.
	jp	error

error5:
	pop	hl		; Mata el ret.
	ld	de, txterror2	;Error del archivo que no se puede abrir cerrando archivo.
	jp	error

txterror11:	db	"Esto no es MSX-DOS2.Carga los drivers.",13,10,"$"
error11:
	ld	de, txterror11	;Error no es MSX-DOS2
	jp	error

;Fin del subproceso de salida del programa con mensaje de error.
;-----------------------------------------------------------------------------	


;-----------------------------------------------------------------------------
;
; Subrutinas (vienen de un CALL):

;-----------------------------------------------------------------------------
;
; Espera al ideready de la tarjeta SD.
_ideready:
	ideready
	ret

;-----------------------------------------------------------------------------
;
; Saltar espacios de una cadena de carácteres

saltaspacio:			;Salta todos los espacios en la lectura de cadena de carácteres.
	ld	a, (hl)
	cp	" "
	ret	nz		;Si hay otra cosa que no sea espacios fin de la subrutina.
	inc	hl
	jp	saltaspacio	;Bucle saltar espacios.

;-----------------------------------------------------------------------------
;
; Convierte una cadena numérica de decimal a hexadecimal.
; El resultado lo pone en bc y de

dec2hex:
	ld	bc, 0
	ld	de, 0
dec2hex2:
	inc	hl		;lee la cadena numérica en texto.
	ld	a, (hl)
	cp	" "
	ret	z		;Si hay un espacio fin de la lectura. Sale de la subrutina
	ret	c		;Si no hay nada fin de la lectura. Sale de la subrutina.
	sub	#30		;Lo pasa a número de variable.(30 a 39 ASCII).
	cp	10
	jp	nc, dec2hex3	;Si no es un número muestra texto y fin.
	push	af
	call	mulbcdx10	;Multiplica por 10 el número.
	pop	af
	add	a, d
	ld	d, a
	ld	a, c
	adc	a, 0
	ld	c, a
	ld	a, b
	adc	a, 0
	ld	b, a
	jp	dec2hex2	;Va haciendo bucle hasta tener el número en HEX.
dec2hex3:
	pop	hl		;Mata el RET del stack pointer. (Extrae del SP la llamada del CALL y lo pone en HL por ejemplo).
	jp	muestratexto	;Salto incondicional de muestra texto y fin.

;-----------------------------------------------------------------------------
;
; Multiplica un valor BCD x10

mulbcdx10:
	or	a
	rl	d
	rl	c
	rl	b
	ld	ixh, b
	ld	ixl, c
	ld	iyh, d
	or	a
	rl	d
	rl	c
	rl	b
	or	a
	rl	d
	rl	c
	rl	b
	ld	a, d
	add	a, iyh
	ld	d, a
	ld	a, c
	adc	a, ixl
	ld	c, a
	ld	a, b
	adc	a, ixh
	ld	b, a
	ret


;-----------------------------------------------------------------------------
;
; Carga las variables ADPCM a la Flashjacks
; Secuencial:Orden,LoadCommand,filename,Dir,Value,MuteSCC,MuteFM.

load_ADPCM:	
	di
	IDE_ON
	ideready
	
	ld	a, (VAR_ROLLWAVS)	;Primer registro de carga canción. Secuencial 00 a 49d.
	ld	(ROLLWAVS),a		;Ingresa registro parámetros del ADPCM. Valor RollWavs.
	ld	a, (VAR_TIPOMUSICWAV)	;Load comando musica.(Load sin repetición,Load con repetición,FadeOut,Stop,PauseON,PauseOFF)
	ld	(TIPOMUSICWAV),a	;Ingresa registro parámetros del ADPCM. Valor TipoMusicWav.
	ld	a, (VAR_FJ_CLUS)	;Top Cluster archivo abierto. Alto.
	ld	(FJ_CLUSH_FB),a		;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (VAR_FJ_CLUS+1)	;Top Cluster archivo abierto. Bajo.
	ld	(FJ_CLUSL_FB),a		;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (VAR_FJ_TAM)		;Tamaño archivo abierto. Alto3.
	ld	(FJ_TAM3_FB),a		;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (VAR_FJ_TAM+1)	;Tamaño archivo abierto. Alto2.
	ld	(FJ_TAM2_FB),a		;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (VAR_FJ_TAM+2)	;Tamaño archivo abierto. Alto1.
	ld	(FJ_TAM1_FB),a		;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (VAR_FJ_TAM+3)	;Tamaño archivo abierto. Bajo.
	ld	(FJ_TAM0_FB),a		;Ingresa el tamaño del archivo. Bajo. 
	ld	a, (VAR_DIRCOMPARE)	;Dirección A15-A8 de lectura.
	ld	(DIRCOMPAREH),a		;Ingresa registro parámetros del ADPCM. Valor DirRamCompareH. Solo compara una única dirección para todo el proceso. La última entrada será la válida para todo.	
	ld	a, (VAR_DIRCOMPARE+1)	;Dirección A7-A0 de lectura.
	ld	(DIRCOMPAREL),a		;Ingresa registro parámetros del ADPCM. Valor DirRamCompareL.		
	ld	a, (VAR_VALUERAM)	;Valor D7-D0 de lectura de la dirección anterior.
	ld	(VALUERAM),a		;Ingresa registro parámetros del ADPCM. Valor ValueRam.
	ld	a, (VAR_MUTESCC)	;Valor de mute en los canales SCC+PSG
	ld	(MUTESCC),a		;Ingresa registro parámetros del ADPCM. Valor MuteSCC.
	ld	a, (VAR_MUTEFM)		;Valor de mute en los canales SCC+PSG
	ld	(MUTEFM),a		;Ingresa registro parámetros del ADPCM. Valor MuteFM.

	ld	a,074h			;Le da al precarga.
	ld	(IDE_CMD),a
	ideready			; Hasta que no termina la carga no avanza.
	
	IDE_OFF
	ei

	ret

;-----------------------------------------------------------------------------
;
; Resetea las variables ADPCM de la Flashjacks

reset_ADPCM:	
	di
	IDE_ON
	ideready
	
	ld	a,075h			;Le da al reset.
	ld	(IDE_CMD),a
	ideready			;Hasta que no termina la carga no avanza.
	
	IDE_OFF
	ei

	ret

;-----------------------------------------------------------------------------
;
; Lee del archivo completo y lo pasa a buffer_FILE.

read_FILE:	
	ld	hl,buffer_FILE	;Rellena con ceros 12288 bytes del buffer_FILE
	ld	(hl),00		;Valor a rellenar.
	ld	bc,12288	;Cantidad a rellenar.	
	ld	de,buffer_FILE+1;Repetición.
	ldir
		
	ld	a,0		;Lee el número de unidad lógica de acceso.
	ld	(FCB),a		;Guarda la unidad lógica en el FCB.
							; Pone espacios en el nombre de archivo dentro del FCB.
	ld	hl,FCB+1	; Transfiere el FCB a hl.
	ld	a,8+3		; Nombre+ext a borrar con espacios.
B_Name2:ld	(hl),020h	; Carga el caracter espacio en la ubicación del puntero de HL.
	inc	hl		; Incrementa el puntero de FCB.
	dec	a		; Decrementa posiciones restantes.
	jp	nz,B_Name2	; Bucle borrado Nombre archivo en FCB.

				; Convierte de formato nombre archivo FIB a FCB
	ld	hl,FIB+1	; Transfiere el nombre del archivo de FIB a FCB.
	ld	de,FCB+1
	ld	bc,8		; 8 carácteres.
B_Name3:	
	ldi			; Avanza de uno en uno.
	jp	c, B_Punto	; Si llega al final considera lo siguiente como un punto.
	ld	a,(hl)		; Si no ha llegado al final lee el contenido siguiente por si es un punto.
	cp	02Eh		; Mira si hay un punto para tratarlo como extensión.	
	jp	z,B_Punto	; Salto por punto.
	xor	a		; Borra a para evitar afectar al carry.
	jp	B_Name3		; Si no, va incrementado posiciones.

B_Punto:
	inc	hl		; Quitamos "."
	ld	de,FCB+1+8	; Nos vamos a la posición de extensión.
	ld	bc,3		
	ldir			; Aquí copia los tres carácteres siguientes.
		
	ld	bc,0024		; Prepare the FCB. Bytes 12 en adelante.
	ld	de,FCB+13
	ld	hl,FCB+12
	ld	(hl),b
	ldir			; Initialize the second half with zero

	ld	c,0fh		; Abrimos el archivo. (Acordarse de cerrarlo)
	ld	de,FCB
	call	BDOS		
	cp	0ffh
	jp	z, error5	; Si no se deja abrir, mensaje de error y cierre archivo.
	
	ld	hl,8		; Bytes por bloque. Le ponemos 8 byte. Con 1 byte por bloque casca a partir de 10kB
	ld	(FCB+14),hl

	ld	c,1ah		; Le dice a la unidad que el buffer_File es donde debe de volcar los datos.
	ld	de,buffer_FILE	; Lo direcciona a esta posición de memoria.
	call	BDOS		; Set disk transfer address 

	ld	c,027h		; Random Block Read. Lee varios bloques(instrucción 27h). 
	ld	de,FCB		; Da el puntero de FCB
	ld	hl, 1536	; Número de bloques a leer. 12288bytes = 1536bloques X 8bytes como tope.
	call	BDOS		; Open file
	
	ld	c, 10h		;Cierre del archivo.
	ld	de,FCB
	call	BDOS
	
	ld	a,(FIB+24)	; Compara con los 3 bytes del tamaño del archivo indicado en el FIB.
	ld	b,0
	cp	b
	jp	nz, error4	; Si es diferente a 0, sobrepasa la capacidad de lectura.

	ld	a,(FIB+23)
	ld	b,0
	cp	b
	jp	nz, error4	; Si es diferente a 0, sobrepasa la capacidad de lectura.

	ld	a,(FIB+22)
	ld	b,30h
	cp	b
	jp	nc, error4	; Si es sobrepasa el 30h, sobrepasa la capacidad de lectura. (30 00 --> 12288)

	ret			; Fin del proceso de lectura.

;-----------------------------------------------------------------------------
;
; Transfiere una línea del buffer_FILE acomandos FlashJacks.

Trans_buf:
	ld	hl,buffer_FILE	; Transfiere el buffer_File
Trans_buf0:
	ld	a, 00h			;Resetea las variables Flashjacks
	ld	(VAR_ROLLWAVS),a	;Ingresa registro parámetros del ADPCM. Valor RollWavs.
	ld	(VAR_TIPOMUSICWAV),a	;Ingresa registro parámetros del ADPCM. Valor TipoMusicWav.
	ld	(VAR_FJ_CLUS),a		;Ingresa la dirección cluster el archivo. Alto. 
	ld	(VAR_FJ_CLUS+1),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	(VAR_FJ_TAM),a		;Ingresa el tamaño del archivo. Alto3. 
	ld	(VAR_FJ_TAM+1),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	(VAR_FJ_TAM+2),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	(VAR_FJ_TAM+3),a	;Ingresa el tamaño del archivo. Bajo. 
	ld	(VAR_DIRCOMPARE),a	;Ingresa registro parámetros del ADPCM. Valor DirRamCompareH. Solo compara una única dirección para todo el proceso. La última entrada será la válida para todo.	
	ld	(VAR_DIRCOMPARE+1),a	;Ingresa registro parámetros del ADPCM. Valor DirRamCompareL.		
	ld	(VAR_VALUERAM),a	;Ingresa registro parámetros del ADPCM. Valor ValueRam.
	ld	(VAR_MUTESCC),a		;Ingresa registro parámetros del ADPCM. Valor MuteSCC.
	ld	(VAR_MUTEFM),a		;Ingresa registro parámetros del ADPCM. Valor MuteFM.
	
	ld	a, (hl)		
	cp	"@"		; Lo compara con un inicio de línea.
	jp	z, Trans_buf1
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	jp	Trans_buf0	; Si no es nada de lo anterior repite bucle.

Trans_buf1:
	inc	hl		; Primera variable a guardar. ROLLWAVS
	call	Texttovar	; Busca primera variable en formato texto y lo mete en a.
	ld	(VAR_ROLLWAVS),a; Mete en ROLLWAVS la primera variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido va a la siguiente @ o fin de archivo.

Trans_buf2:
	ld	a, (hl)		; Busqueda siguiente variable.
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf3
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	cp	"@"		; Lo compara con un inicio de linea.
	jp	z, Trans_buf1	; Fin del buscador de línea.
	jp	Trans_buf2	; Si no es nada de lo anterior repite bucle.

Trans_buf3:
	inc	hl		; Segunda variable a guardar. TIPOMUSICWAV
	ld	a, (hl)		
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf4	; Si no hay nada en esta variable la ignora y a la siguiente.
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	cp	" "		; Lo compara con un espacio.
	jp	z, Trans_buf3	; Si hay un espacio, avanza una posición.
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	call	Texttovar	; Busca segunda variable en formato texto y lo mete en a.
	ld	(VAR_TIPOMUSICWAV),a; Mete en TIPOMUSICWAV la segunda variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido error va a la siguiente @ o fin de archivo.

Trans_buf4:
	ld	a, (hl)		; Busqueda siguiente variable.
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf5
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	cp	"@"		; Lo compara con un inicio de linea.
	jp	z, Trans_buf1	; Fin del buscador de línea.
	jp	Trans_buf4	; Si no es nada de lo anterior repite bucle.

Trans_buf5:
	inc	hl		; Tercera variable a guardar. Cluster y Tamaño.
	ld	a, (hl)		
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf6	; Si no hay nada en esta variable la ignora y a la siguiente.
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	cp	" "		; Lo compara con un espacio.
	jp	z, Trans_buf5	; Si hay un espacio, avanza una posición.
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	
	;Borra filename
	push	hl
	ld	hl,filename	;Rellena con ceros 13 bytes del filename
	ld	(hl),00		;Valor a rellenar.
	ld	bc,8+3+1+1	;Cantidad a rellenar +1.	
	ld	de,filename+1	;Repetición.
	ldir
	pop	hl
	
	;Transfiere el nombre del archivo a su variable.
	xor	a		
	ld	de, filename
	ld	bc,12		; 8 + punto + 3 carácteres.

Trans_buf5a:	
	ldi
	ld	a, (hl)
	cp	","
	jp	z, Trans_buf5b	;Si encuentra una coma, finaliza la lectura.
	jp	c, Trans_buf5b	;Si lee todos los cáracteres, finaliza la lectura.
	jp	Trans_buf5a	;Bucle lectura nombre de archivo.

Trans_buf5b:
	; Cargar archivo en FIB
	push	hl
	ld	de, filename	;Obtiene el File Info Block del
	ld	b, 0		;fichero.
	ld	hl, 0
	ld	ix, FIB
	ld	c, #40
	call	BDOS
	pop	hl
	or	a
	jp	nz, Trans_buf0	;Salta si error del archivo no se puede abrir. Ignora toda la línea restante.

	; Transfiere Cluster y Tamaño a sus respectivas variables.
	ld	a, (FIB+19)		;Top Cluster archivo abierto. Alto.
	ld	(VAR_FJ_CLUS),a		;Ingresa la dirección cluster el archivo. Alto. 
	ld	a, (FIB+20)		;Top Cluster archivo abierto. Bajo.
	ld	(VAR_FJ_CLUS+1),a	;Ingresa la dirección cluster el archivo. Bajo. 
	ld	a, (FIB+21)		;Tamaño archivo abierto. Alto3.
	ld	(VAR_FJ_TAM),a		;Ingresa el tamaño del archivo. Alto3. 
	ld	a, (FIB+22)		;Tamaño archivo abierto. Alto2.
	ld	(VAR_FJ_TAM+1),a	;Ingresa el tamaño del archivo. Alto2. 
	ld	a, (FIB+23)		;Tamaño archivo abierto. Alto1.
	ld	(VAR_FJ_TAM+2),a	;Ingresa el tamaño del archivo. Alto1. 
	ld	a, (FIB+24)		;Tamaño archivo abierto. Bajo.
	ld	(VAR_FJ_TAM+3),a	;Ingresa el tamaño del archivo. Bajo. 

Trans_buf6:
	ld	a, (hl)		; Busqueda siguiente variable.
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf7
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	cp	"@"		; Lo compara con un inicio de linea.
	jp	z, Trans_buf1	; Fin del buscador de línea.
	jp	Trans_buf6	; Si no es nada de lo anterior repite bucle.

Trans_buf7:
	inc	hl		; Cuarta variable a guardar. DIRCOMPARE y DIRCOMPARE+1
	ld	a, (hl)		
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf8	; Si no hay nada en esta variable la ignora y a la siguiente.
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	cp	" "		; Lo compara con un espacio.
	jp	z, Trans_buf7	; Si hay un espacio, avanza una posición.
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	call	Texttovar	; Busca cuarta variable en formato texto y lo mete en a.
	ld	(VAR_DIRCOMPARE),a; Mete en DIRCOMPARE la cuarta variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido error va a la siguiente @ o fin de archivo.
	call	Texttovar	; Busca cuarta variable en formato texto y lo mete en a.
	ld	(VAR_DIRCOMPARE+1),a; Mete en DIRCOMPARE+1 la cuarta variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido error va a la siguiente @ o fin de archivo.

Trans_buf8:
	ld	a, (hl)		; Busqueda siguiente variable.
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_buf9
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	cp	"@"		; Lo compara con un inicio de linea.
	jp	z, Trans_buf1	; Fin del buscador de línea.
	jp	Trans_buf8	; Si no es nada de lo anterior repite bucle.

Trans_buf9:
	inc	hl		; Quinta variable a guardar. VALUERAM
	ld	a, (hl)		
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_bufA	; Si no hay nada en esta variable la ignora y a la siguiente.
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	cp	" "		; Lo compara con un espacio.
	jp	z, Trans_buf9	; Si hay un espacio, avanza una posición.
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	call	Texttovar	; Busca quinta variable en formato texto y lo mete en a.
	ld	(VAR_VALUERAM),a; Mete en VALUERAM la quinta variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido error va a la siguiente @ o fin de archivo.

Trans_bufA:
	ld	a, (hl)		; Busqueda siguiente variable.
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_bufB
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	cp	"@"		; Lo compara con un inicio de linea.
	jp	z, Trans_buf1	; Fin del buscador de línea.
	jp	Trans_bufA	; Si no es nada de lo anterior repite bucle.

Trans_bufB:
	inc	hl		; Sexta variable a guardar. MUTESCC
	ld	a, (hl)		
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_bufC	; Si no hay nada en esta variable la ignora y a la siguiente.
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	cp	" "		; Lo compara con un espacio.
	jp	z, Trans_bufB	; Si hay un espacio, avanza una posición.
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	call	Texttovar	; Busca sexta variable en formato texto y lo mete en a.
	ld	(VAR_MUTESCC),a ; Mete en MUTESCC la sexta variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido error va a la siguiente @ o fin de archivo.

Trans_bufC:
	ld	a, (hl)		; Busqueda siguiente variable.
	cp	","		; Lo compara con una separación de variable.
	jp	z, Trans_bufD
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	inc	hl
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_buf0	; Fin del buscador de línea.
	cp	"@"		; Lo compara con un inicio de linea.
	jp	z, Trans_buf1	; Fin del buscador de línea.
	jp	Trans_bufC	; Si no es nada de lo anterior repite bucle.

Trans_bufD:
	inc	hl		; Septima variable a guardar. MUTEFM
	ld	a, (hl)		
	cp	00h		; Lo compara con fin de fichero.
	jp	z, Trans_fin	; Fin del buscador de líneas.
	cp	" "		; Lo compara con un espacio.
	jp	z, Trans_bufD	; Si hay un espacio, avanza una posición.
	cp	";"		; Lo compara con un fin de linea.
	jp	z, Trans_bufE	; Fin del buscador de línea.
	call	Texttovar	; Busca septima variable en formato texto y lo mete en a.
	ld	(VAR_MUTEFM),a  ; Mete en MUTEFM la septima variable.
	ld	a,b
	cp	1		; Mira si ha habido error.
	jp	z,Trans_buf0	; Si ha habido error va a la siguiente @ o fin de archivo.

Trans_bufE:	
	push	hl
	call	load_ADPCM	; Ejecuta comandos Flashjacks.
	
	
	; Si llega aquí imprime por pantalla linea XX ejecutada correctamente
	ld	de, txtEjec	;Ejecutada linea 
	ld	c, 9
	call	BDOS
	ld	a,(VAR_ROLLWAVS)
	call	PrintvarNE	;Imprime variable sin enter.
	ld	de, txtEjec2	;correctamente...
	ld	c, 9
	call	BDOS


	pop	hl
	jp	Trans_buf0	; Va a la siguiente linea.

Trans_fin:
	ret

;-----------------------------------------------------------------------------
;
; Busca variable hexadecimal en formato texto y lo mete en a. Incrementa posiciones en HL.

Texttovar:
	xor	a		;Borra a y los flags para no afectar a la comparación.
	ld	a, (hl)		;Transfiere el valor
	sub	30h		;Lo pasa a número de variable.(30 a 39 ASCII).
	cp	0Ah
	jp	m, Textt2	;Si es un número decimal lo trata. Si no busca un hexadecimal.(a < arg)

Textt1:	xor	a		;Borra a y los flags para no afectar a la comparación.
	ld	a, (hl)		;Transfiere el valor
	or	20h		;Pasa de si es mayusculas o minusculas.
	sub	61h		;Lo pasa a número hexa de variable.(41-61h a 46-66h ASCII).
	cp	6
	jp	nc, Texttbad	;Si no es un número decimal o hexadecimal, da error.(a >= arg)
	add	a, 0Ah		;Le suma A para alcanzar las posiciones 

Textt2:
	rla			;Rota 4 veces 1 bit a la izquierda.
	rla	
	rla	
	rla	
	and	0F0h		;Borra las unidades, dejando solo las decenas.
	push	af
	inc	hl		;Incrementa la posición del texto en 1.
	xor	a		;Borra a y los flags para no afectar a la comparación.
	ld	a, (hl)		;Transfiere el valor
	sub	30h		;Lo pasa a número de variable.(30 a 39 ASCII).
	cp	0Ah
	jp	m, Textt4	;Si es un número decimal lo trata. Si no busca un hexadecimal.(a < arg)

Textt3:	xor	a		;Borra a y los flags para no afectar a la comparación.
	ld	a, (hl)		; Transfiere el valor
	or	20h		;Pasa de si es mayusculas o minusculas.
	sub	61h		;Lo pasa a número hexa de variable.(41-61h a 46-66h ASCII).
	cp	6
	jp	nc, Texttbad2	;Si no es un número decimal o hexadecimal, da error. (a >= arg)
	add	a, 0Ah		;Le suma A para alcanzar las posiciones 

Textt4:
	ld	c,a		;Transfiere las unidades a c.
	pop	af		;Recupera las decenas.
	add	a,c		;Le suma las unidades.
	ld	b, 0		;Quita el código de error.
	inc	hl		;Incrementa la posición del texto en 1.	
	ret

Texttbad2:
	pop	af		;Quita de la pila a.
	xor	a
	ld	b, 1		; Error.
	ret
Texttbad:
	xor	a
	ld	b, 1		; Error.
	ret

;-----------------------------------------------------------------------------
;
; Imprime variable a por pantalla. Numero hexadecimal.

Printvar: ;Haciendo enter.
	; Poner en a el número a mostrar por pantalla
	push	hl
	ld	l,a
	sra	a
	sra	a
	sra	a
	sra	a		;Desplaza "a" cuatro bits a la derecha 
	and	a,0fh		;Borra los cuatro bits de la izquierda. Tenemos ahora las decenas en las unidades.
	add	a,30h		;Le suma 30h y convertimos el numero en ASCII
	cp	3ah		;Compara para ver si supera el número 9 ASCII para saltar a las letras.
	jp	m,Imtexto	; Si el número es negativo a-cp. Si está dentro de 0-9 salta a imtexto
	add	a,7h		; Si no está entre 0-9 añade 7 para alzanzar las letras A-F del ASCII
Imtexto:
	ld	(Caracter),a	;Imprime las decenas del número por pantalla
	ld	a,l		;Carga en a el numero de la variable l
	and	a,0fh		;Borra los cuatro bits de la izquierda. Tenemos ahora las unidades.
	add	a,30h		;Le suma 30h y convertimos el numero en ASCII
	cp	3ah		;Compara para ver si supera el número 9 ASCII para saltar a las letras.
	jp	m,Imtexto2	; Si el número es negativo a-cp. Si es está dentro de 0-9 y salta a imtexto2
	add	a,7h		; Si no está entre 0-9 añade 7 para alzanzar las letras A-F del ASCII
Imtexto2:
	ld	(Caracter+1),a	;Imprime las unidades del número por pantalla
	ld	c, 9
	ld	de, Caracter	;Imprime por pantalla un caracter con enter.
	call	BDOS
	pop	hl
	ret

PrintvarNE: ;Sin hacer enter.
	; Poner en a el número a mostrar por pantalla
	push	hl
	ld	l,a
	sra	a
	sra	a
	sra	a
	sra	a		;Desplaza "a" cuatro bits a la derecha 
	and	a,0fh		;Borra los cuatro bits de la izquierda. Tenemos ahora las decenas en las unidades.
	add	a,30h		;Le suma 30h y convertimos el numero en ASCII
	cp	3ah		;Compara para ver si supera el número 9 ASCII para saltar a las letras.
	jp	m,Imtexto3	; Si el número es negativo a-cp. Si está dentro de 0-9 salta a imtexto
	add	a,7h		; Si no está entre 0-9 añade 7 para alzanzar las letras A-F del ASCII
Imtexto3:
	ld	(Caracter_NE),a	;Imprime las decenas del número por pantalla
	ld	a,l		;Carga en a el numero de la variable l
	and	a,0fh		;Borra los cuatro bits de la izquierda. Tenemos ahora las unidades.
	add	a,30h		;Le suma 30h y convertimos el numero en ASCII
	cp	3ah		;Compara para ver si supera el número 9 ASCII para saltar a las letras.
	jp	m,Imtexto4	; Si el número es negativo a-cp. Si es está dentro de 0-9 y salta a imtexto2
	add	a,7h		; Si no está entre 0-9 añade 7 para alzanzar las letras A-F del ASCII
Imtexto4:
	ld	(Caracter_NE+1),a	;Imprime las unidades del número por pantalla
	ld	c, 9
	ld	de, Caracter_NE	;Imprime por pantalla un caracter sin enter.
	call	BDOS
	pop	hl
	ret


;-----------------------------------------------------------------------------
;
; Imprime variable hl el número de carácteres de bc.

	push	hl
	push	bc
	push	de
	;ld	hl,Marca_LST	; Transfiere 
	ld	de,Valor_N_CAS
	ld	bc,4
	ldir

	ld	de, Valor_N_CAS	;Fija el puntero en el texto de CargaWAV.
	ld	c, 9
	call	BDOS
	pop	de
	pop	bc
	pop	hl

	ret


;-----------------------------------------------------------------------------
;Variables del entorno.

oldstack:	dw	0
PCMport:	db	0
tamanyoPCM:	dw	0
options:	db	%0
options2:	db	%0
pcmsize:	dw	0
tamanyo:	db	0,0,0,0
tamanyoc:	db	0,0,0,0
unidad:		db	0
slotide:	db	0
cabezas:	db	0
sectores:	db	0
devicetype:	db	0
atapic:		ds	18
start:		db	0,0,0,0
start_:		db	0,0,0,0
final:		db	0,0,0,0
final_:		db	0,0,0,0
frmxint:	db	2
HMMV:		db	0,0,0,0,0,0,212,1,0,0,#C0
HMMC1:		db	64,0,53
pagvram:	db	0
		db	128,0,106,0,0,#F0

HMMC2:		db	0,0,0
pagvram2:	db	0
		db	0,1,212,0,0,#F0

transback:	db	0,0,0,0,0,1,212,0,0,0,#F0
transback2:	db	0,0,0,0,0,0,0,1,0,1,212,0,0,0,#D0


VAR_ROLLWAVS	db	0
VAR_TIPOMUSICWAV	db	0
VAR_DIRCOMPARE	db	0,0
VAR_VALUERAM	db	0
VAR_MUTESCC	db	0
VAR_MUTEFM	db	0
VAR_FJ_CLUS	db	0,0
VAR_FJ_TAM	db	0,0,0,0

datovideo:	db	0
TempejeY:	db	0
MultiVDP:	db	0
regside1:	db	0
regside2:	db	0
regside3:	db	0
regside4:	db	0
regside1c:	db	0
regside2c:	db	0
regside3c:	db	0
regside4c:	db	0
atapiread:	db	#A8,0,0,0,0,0,0,0,0,0,0,0
modor800:	db	0
Z80B:		db	0
filehandle:	db	0
filehandle2:	db	0
filename:	ds	64
fileram:	ds	20
fileboot:	db	5Ch,"BOY_BIOS.BIN",0 ; el 5Ch es contrabarra para ir a directorio raiz.
backfile:	ds	64
safe38:		ds	5
buffer:		ds	2
FIB:		ds	64
sonido:		dw	0
sonido2:	dw	0
idevice:	dw	0
Bytes_Leidos:	db	0
TipoFile:	db	0
Textfile:	db	"00000000000",13,10,"$"
Nombre_CAS	db	"Nombre CAS:","$"
Valor_N_CAS	db	"              ",13,10,"$"

Marca_CAS	db	1Fh,0A6h,0DEh,0BAh,0CCh,13h,7Dh,74h
File_Name	db	"           ",13,10,"$"
Marca_LST:	db	"lst"
Marca_WAV:	db	"wav"
Caracter	db	"00",13,10,"$"
Caracter_NE	db	"00","$"

buffer_FILE:	ds	12288 ; Reservamos 12288bytes.
Fbuffer_File:	db	13,10,"$"


;Fin de las variables del entorno.
;-----------------------------------------------------------------------------

;Fin del programa completo.
;-----------------------------------------------------------------------------
end