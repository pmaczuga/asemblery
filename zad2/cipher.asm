; Paweł Maczuga
; Operacje na plikach
; Szyfr Vigenere'a


dane1 segment
	arg db 200 dup('$')							; sparsowane argumenty odzielone znakiem $
	arg_l db 10 dup(0)							; tablica długości kolejnych argumentów (l - length)
	arg_o dw 10 dup(?)							; tablica offsetów pierwszych znaków argumentów (o - offset)
	arg_n db 0									; ilość argumentów (n - number)
	
	new_line db 13,10,"$"						; przejście do nowej linii
	
	version db ?								; wesja - szyfrowanie - 0, deszyfrowanie - 1
	input_file db 13 dup(0)						; nazwa pliku wejściowego
	output_file db 13 dup(0)					; nazwa pliku wyjściowego
	code db 50 dup(?)							; kod - słowo szyfrujące
	code_l db ?									; długość kodu
	
	input_handler dw ?
	output_handler dw ?
	
	input_buffer db 1024 dup(?)					; bufor wejściowy
	output_buffer db 1024 dup(?)				; bufor wyjściowy
	input_buffer_pos dw 1024					; obecna pozycja bufora wejściowego, na początku 1024 - spowoduje to wczytanie z pliku do bufora
	output_buffer_pos dw 0						; obecna pozycja bufora wyjściowego, na początku 0
	buffer_loaded dw ?							; ilość znaków wczytanych do bufora
	eof db 0									; flaga końca pliku (end of file)

;												; komunikaty o błędach
	error_number_of_arguments db "Error. Zla liczba argumentow. Podaj 3 lub 4",13,10,"$"
	error_decrypt db "Error. Gdy podane sa cztery argumenty pierwszym powinno byc '-d' - decrypt",13,10,"$"
	error_input_file db "Error. Problem z plikiem wejsciowym",13,10,"$"
	error_output_file db "Error. Problem z plikiem wyjsciowym",13,10,"$"
	error_input_read db "Error. Blad odczytu z pliku wejsciowego",13,10,"$"
	error_output_write db "Error. Blad zapisu do pliku wyjsciowego",13,10,"$"
	
dane1 ends

;-------------------------------------------------------------------------------------------------------------------------
;---------------------------------------SEGMENT-KODU----------------------------------------------------------------------
code1 segment
	start:
	
	mov ax,seg w_stos							; inicjalizacja stosu
	mov ss,ax
	mov sp,offset w_stos
	
;-------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------MAKRA-------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------


	exit macro									; makro kończące program
		mov ah,4ch
		int 21h
	endm
	
	print_string macro							; makro wypisujące napis z ds:dx
		mov ah,9h
		int 21h
	endm
	
	error1 macro								; Błąd 1 - zła liczba argumentów
		mov dx,offset error_number_of_arguments
		print_string
		exit
	endm
	
	error2 macro								; Błąd 2 - błędna konstrukcja argumentu informującego o deszyfrowaniu
		mov dx,offset error_decrypt
		print_string
		exit
		endm
		
	error3 macro								; Błąd 3 - Problem z otworzeniem pliku wejściowego
		mov dx,offset error_input_file
		print_string
		exit
	endm
	
	error4 macro								; Błąd 4 - Problem z otworzeniem pliku wyjściowego
		mov dx,offset error_output_file
		print_string
		exit
	endm
	
	error5 macro								; Błąd 5 - Błąd odczytu z pliku wejściowego
		mov dx,offset error_input_read
		print_string
		exit
	endm
	
	error6 macro								; Błąd 6 - Błąd zapisu do pliku wyjściowego
		mov dx,offset error_output_write
		print_string
		exit
	endm
	
;-------------------------------------------------------------------------------------------------------------------------
;---------------------------------------POCZĄTEK-PROGRAMU-----------------------------------------------------------------	
	
	call parse									; parsowanie argumentów
	call check_arguments						; procedura sprawdzająca poprawność argumentów
	call open_files								; procedura otwierająca pliki
	call cipher									; właściwa procedura szyfrująca
	call close_files							; procedura zamykająca pliki
	
	
	exit										; makro kończące program
	
;---------------------------------------KONIEC-PROGRAMU-------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------
	


;-------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------PROCEDURY-----------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------
	
;--------------------------------------------------------------------
;	parse
;
;		procedura parsująca argumenty
;--------------------------------------------------------------------
	parse proc
		push ax
		push cx
		push si
		push di
		
		mov ax,ds								; ds - domyślny segment z linią komend
		mov es,ax								; przenoszę do es
		
		mov ax,dane1							; segment z daymi
		mov ds,ax								; do ds
		mov di,offset arg						; do di offset arg - ciągu znaków, gdzie będą zapisywane argumenty bez białych aznków
		
		mov cl,byte ptr es:[080h]				; do cl - ilość znaków w lini komend 
		cmp cl,0								; cl = 0 - brak argumentów
		je end_parse							; więc, zakończ parsowanie
		cmp cl,1								; jeden znak po nazwie programu - spacja, więc również brak argumentów
		je end_parse
		
		mov si,082h								; początek ciągu znków w lini komend
		
		loop_parse:								; główna pętla procedury parse
		
			call first_not_white				; procedura pomijająca białe znaki
			cmp cl,1							; sprawdzam czy skończyły się znaki w lini komend
			je end_parse						; jeśli tak kończę parsowanie
			
			call copy_argument					; procedura kopiująca kolejne znaki argumentu do pamięci
			inc di								; zwiększam di - po żeby po argumencie pojawił się znak $
			cmp cl,1							; znowu sprawdzam czy skończyły się znaki
			je end_parse
			
		jmp loop_parse
		
		
		end_parse:
			pop di
			pop si
			pop cx
			pop ax
			ret
	parse endp
	
;--------------------------------------------------------------------
;	first_not_white
;
;		wejście:
;			si - pozycja białego znaku
;			cl - ilość pozostałych znaków w lini komend
;		wyjście:
;			si - pozycja pierwszego niebiałego znaku
;			cl - pozostałe znaki
;--------------------------------------------------------------------
	first_not_white proc
		push ax
		
		loop_first_not_white:
			cmp cl,1							; sprawdzam czy koniec lini komend
			je end_first_not_white				; jeśli tak kończę procedurę
			
			mov al,es:[si]						; do al kod znaku
			
			cmp al,32d							; sprawdzam czy jest to spacja
			je loop_first_not_white_next		; jeśli tak kontynuuję pętlę
			cmp al,9d							; jeśli nie sprawdzam czy jest to tab
			je loop_first_not_white_next
			
			jmp end_first_not_white				; skoro nie jest to ani spacja ani tab, to kończę pętlę i procedurę
			
			loop_first_not_white_next:			; kontynuacja pętli - gdy znakiem będzie spacja albo tab
				dec cl							; zmniejszam cl o 1 - licznik znaków do końca linii
				inc si							; si - na następny znak
		jmp loop_first_not_white

		end_first_not_white:					; koniec procedury
			
			pop ax
			ret
			
	first_not_white endp
	
;--------------------------------------------------------------------
;	copy_argument
;
;		wejście:
;			es:[si] - pozycja początku nowego argumentu
;			ds:[di] - tu bedę wpisywał znaleziony argument
;			cl - ilość pozostałych znaków w lini komend
;		wyjście:
;			si - pozycja pierwszego białego znaku
;			di - wskazuje miejsce po ostatnim wpisanym znaku
;			cl - pozostałe znaki
;			arg - argument umieszczony w odpowiednim miejscu w pamięci
;			arg_l - długość argumentu umieszczona w odpowiedniej tablicy
;			arg_o - offset początku argumentu do tablicy
;			arg_n - zwiększenie liczby w pamięci odpowiadającej ilości argumentów o 1
;--------------------------------------------------------------------
	copy_argument proc
		push ax
		push bx
		
		mov bl,byte ptr ds:[arg_n]				; do bl - numer argumentu
		mov bh,0								; zerowanie bh - żeby w bx było to samo co w bl
		shl bx,1								; przesuwam bx o jeden bit w lewo, czyli mnoże przez 2 - kolejne offsety w tablicy mają 2 bajty
		mov word ptr ds:[arg_o + bx],di			; ds:[di] - pierwszy znak nowego argumentu, więc di kopiuję do tablicy offsetów
		mov ah,0								; ilość znaków argumentu - żeby długość argumentu zpisać do odpowiedniej tablicy
		
		loop_copy_argument:
		
			cmp cl,1							; sprawdzam czy koniec lini komend
			je end_copy_argument				; jeśli tak kończę procedurę
			
			mov al,es:[si]						; do al kod znaku
			
			cmp al,32d							; sprawdzam czy jest to spacja
			je end_copy_argument				; jeśli tak kończę procedurę
			cmp al,9d							; jeśli nie sprawdzam czy jest to tab
			je end_copy_argument
			
			mov byte ptr ds:[di],al				; znak argumentu do pamięci
			
			inc ah								; długość argumentu +1
			dec cl								; zmniejszam cl o 1 - licznik znaków do końca linii
			inc si								; si - na następny znak
			inc di								; di - na następną pozycję
		
		jmp loop_copy_argument
		
		end_copy_argument:						; koniec procedury
			mov bl,ds:[arg_n]					; do bl - numer argumentu
			mov byte ptr ds:[arg_l + bx],ah		; do tablicy długość argumentu, bh cały czas jest zerem
			inc byte ptr ds:[arg_n]				; ilość argumentów +1
			
			pop bx
			pop ax
			ret
			
	copy_argument endp	
	
;--------------------------------------------------------------------
;	check_arguments
;
;		procedura sprawdzająca poprawność argumentów
;		i kopiująca je do odpowiedniego miejsca w pamięci
;--------------------------------------------------------------------
	check_arguments proc
	
		cmp byte ptr ds:[arg_n],3d				; sprawdzam, czy są 3 argumenty
		je three_arguments
		
		cmp byte ptr ds:[arg_n],4d				; sprawdzam, czy są 4 argumenty
		je four_arguments
		
		error1									; makro - komunikat z odpowiednim błędem i wyjście z programu 
		
		three_arguments:
			mov byte ptr ds:[version],0d		; trzy argumenty, więc szyfrowanie - flaga "0"
			jmp rewrite_arguments
			
		four_arguments:
			cmp byte ptr ds:[arg_l],2d			; sprawdzam czy pierwszy argument ma 2 znaki
			jne error2_check_arguments			; jeśli nie - błąd
			cmp byte ptr ds:[arg],45d			; porównanie pierwszego znaku pierwszego argumentu z 45 - "-"
			jne error2_check_arguments
			cmp byte ptr ds:[arg+1],100d		; porównanie drugiego znaku pierwszego argumentu z 100d - "d"
			jne error2_check_arguments
			mov byte ptr ds:[version],1d		; pierwszy argument - "-d", czyli deszyfrowanie - flaga - "1"
			jmp rewrite_arguments
			
		rewrite_arguments:
			mov bh,0							; zeruję bh - żeby bl=bx
			mov ch,0							; zeruję ch, żeby cl=cx
			mov bl,byte ptr ds:[version]		; do bl (bx) wersja 1 lub 0 - żeby wiadomo było od którego argumentu kopiować
		
			shl bx,1							; mnożę bx przez 2, bo offset ma 2 bajty
			mov si,word ptr ds:[arg_o+bx]		; offset argumentu do si
			mov di,offset input_file			; do di offset miejsca do zapisu
			shr bx,1							; dzielę bx przez 2, bo długości argumentów mają po 1 bajcie
			mov cl,byte ptr ds:[arg_l+bx]		; do cl (cx) długość argumentu
			call copy							; procedura kopiująca cx znaków z ds:[si] do ds:[di]
			inc bx								; zwiękaszam bx - na następny argument
		
			shl bx,1
			mov si,word ptr ds:[arg_o+bx]
			shr bx,1
			mov di,offset output_file
			mov cl,byte ptr ds:[arg_l+bx]
			call copy
			inc bx
		
			shl bx,1
			mov si,word ptr ds:[arg_o+bx]
			shr bx,1
			mov di,offset code
			mov cl,byte ptr ds:[arg_l+bx]
			mov byte ptr ds:[code_l],cl 		; do code_l długość kodu
			call copy
			
			jmp end_check_arguments
			
		error2_check_arguments:
			error2
			
	end_check_arguments:
		ret
		
	check_arguments endp
	
;--------------------------------------------------------------------
;	copy
;
;		wejście:
;			ds:si - skąd kopiować
;			ds:di - dokąd kopiować
;			cx - ilość znaków do skopiowania
;		wyjście:
;			ds:di - skopiowane cx znaków
;
;		procedura kopiująca cx znkaków z ds:si do ds:di
;--------------------------------------------------------------------
	copy proc
		push ax
	
		loop_copy:
			mov al,byte ptr ds:[si]
			mov byte ptr ds:[di],al
			inc si
			inc di
		loop loop_copy
	
		end_copy:
			pop ax
			ret
		
	copy endp

;--------------------------------------------------------------------
;	open_files
;
;		procedura otwierająca wszystkie potrzebne pliki i zapisująca do pamięci handler'y
;--------------------------------------------------------------------
	open_files proc
		push ax
		push cx
		push dx
	
		mov dx,offset input_file				; do dx offset z nazwą pliku wejściowego
		mov al,0								; do al 0 - tylko do odczytu
		mov ah,3dh								; do ah 3dh - otworzenie pliku
		int 21h
		jc error_open_files_input				; jeśli cf=1 - skok do błędu
		mov word ptr ds:[input_handler],ax		; jeśli nie, w ax jest handler - zapisuję go do pamięci
		
		mov dx,offset output_file				; do dx offset z nazwą pliku wyjściowego
		mov cx,0								; do cx 0 - w cx są atrybuty
		mov ah,3ch								; do ah 3ch - stworzenie lub nadpisanie pliku
		int 21h
		jc error_open_files_output				; jeśli cf=1 - skok do błędu
		mov word ptr ds:[output_handler],ax		; jeśli nie w ax jest handler - zapisuję go do pamięci
		
		jmp end_open_files
		
		error_open_files_input:
			error3
			
		error_open_files_output:
			error4
		
		end_open_files:
			pop dx
			pop cx
			pop ax
			ret
		
	open_files endp
	
;--------------------------------------------------------------------
;	close_files
;
;		procedura zamykająca wszystkie potrzebne pliki
;--------------------------------------------------------------------
	close_files proc
		push ax
		push bx
	
		mov bx,ds:[input_handler]				; do bx handler pliku wejściowego
		mov ah,3eh								; zamknięcie pliku
		int 21h
		
		mov bx,ds:[output_handler]				; do bx handler pliku wyściowego
		mov ah,3eh								; zamknięcie pliku
		int 21h
		
		end_close_files:
			pop bx
			pop ax
			ret
		
	close_files endp
	
;--------------------------------------------------------------------
;	getchar
;
;		wejście:
;			ds:[input_buffer_pos] - znak z bufora do wczytania
;
;		wyjście:
;			al - znak z bufora
;
;		procedura zwracająca następny znak z bufora, jeśli nie ma to wczytuję nową partię znaków
;--------------------------------------------------------------------
	getchar proc
		push bx
		push cx
		push dx
		push ax									; żeby nie modyfikować ah
	
		mov bx,word ptr ds:[input_buffer_pos]	; do bx pozycja bufora
		cmp bx,1024d							; sprawdzam czy skończył się bufor
		jne get_char							; jeśli nie to pobieram znak
		
		load_input_buffer:						; pobranie danych z pliku do bufora
			push bx								; potrzebne jest bx
			mov dx,offset input_buffer			; do dx offset bufora
			mov cx,1024							; do cx 1024 - pobranie 1024 znaków
			mov bx,ds:[input_handler]			; do bx handler do pliku
			mov ah,3fh							; zapisanie cx znaków z pliku bx do ds:[dx]
			int 21h
			jc error5_getchar
			pop bx
			mov bx,0							; pozycja bufora na początek
			mov word ptr ds:[input_buffer_pos],bx	; a potem do pamięci
			mov word ptr ds:[buffer_loaded],ax	; w ax jest ilość wczytanych znaków, do pamięci
			
		
		get_char:
			pop ax
			cmp ds:[buffer_loaded],0			; sprawdzam czy wczytane zostały wszystkie znaki
			je end_of_file						; jeśli tak to koniec pliku, skok do odpowiedniego miejsca
			mov al,byte ptr ds:[input_buffer+bx]	; do al znak z bufora
			dec ds:[buffer_loaded]				; zmniejszam buffer_loaded - ilość znaków wczytanych do bufora
			inc bx								; pozycja bufora na następny znak
			mov word ptr ds:[input_buffer_pos],bx	; a potem do pamięci
			jmp end_getchar
			
			
		error5_getchar:
			error5
			
		end_of_file:
			mov ds:[eof],1d						; do eof - 1 - koniec pliku
		
		end_getchar:
			pop dx
			pop cx
			pop bx
			ret
		
	getchar endp
	
;--------------------------------------------------------------------
;	putchar
;
;		wejście:
;			ds:[output_buffer_pos] - znak z bufora do wczytania
;			al - znak do zapisania
;
;		procedura zapisująca znak z al do bufora, gdy bufor jest pełny zapisuje go do pliku
;--------------------------------------------------------------------
	putchar proc
		push bx
		push cx
		push dx
		push ax									; ax będzie zmieniony
	
		mov bx,word ptr ds:[output_buffer_pos]	; do bx pozycja bufora
		cmp bx,1024d							; sprawdzam czy bufor jest pełny
		jne put_char							; jeśli nie to pobieram znak
		
		save_output_buffer:						; zapisanie danych z bufora do pliku
			push bx 							; potrzebny jest bx
			mov dx,offset output_buffer			; do dx offset bufora
			mov cx,1024							; do cx 1024 - ilość znaków do zapisania
			mov bx,ds:[output_handler]			; do bx handler do pliku
			mov ah,40h							; zapisanie cx znaków z ds:[dx] do pliku bx
			int 21h
			jc error6_putchar
			pop bx
			mov bx,0							; pozycja bufora na początek
		
		put_char:
			pop ax								; żeby odzyskać al
			mov byte ptr ds:[output_buffer+bx],al	; do bufora znak z al
			inc bx								; pozycja bufora na następny znak
			mov word ptr ds:[output_buffer_pos],bx	; a potem do pamięci
			jmp end_putchar
			
			
		error6_putchar:
			error6
			
		
		end_putchar:
			pop dx
			pop cx
			pop bx
			ret
		
	putchar endp
	
;--------------------------------------------------------------------
;		write_output_buffer
;
;			procedura zapisująca do pliku bufer wyjściowy
;--------------------------------------------------------------------
	write_output_buffer proc
		push ax
		push bx
		push cx
		push dx
	
		mov dx,offset output_buffer			; do dx offset bufora
		mov cx,word ptr ds:[output_buffer_pos]		; do cx pozycja bufora - jest to równe ilości znaków w buforze do wypisania
		mov bx,ds:[output_handler]			; do bx handler do pliku
		mov ah,40h							; zapisanie cx znaków z ds:[dx] do pliku bx
		int 21h
		jc error6_write_output_buffer
		jmp end_write_output_buffer
			
		error6_write_output_buffer:
			error6
			
		
		end_write_output_buffer:
			pop dx
			pop cx
			pop bx
			pop ax
			ret
		
	write_output_buffer endp
	
;--------------------------------------------------------------------
;		cipher
;
;			właściwa procedura szyfrująca
;			
;--------------------------------------------------------------------
	cipher proc
		push ax
		
		mov cl,byte ptr ds:[code_l]			; do cl ilość znaków kodu
		mov bx,0							; do bx 0 - pozycja znaku w kodzie

		loop_cipher:						; główna pętla procedury - pobiera, szyfruje i zapisuje kolejne znaki z bufora
		
			call getchar					; pobranie znaku - znak w al
			cmp ds:[eof],1					; sprawdzam czy koniec pliku
			je end_loop_cipher				; jeśli tak - koniec sprawdzania
			
			mov dh,0						; zerowanie dh - dx=dl
			mov dl,byte ptr ds:[code+bx]	; do dl odpowiedni znak z kodu
			
			cmp byte ptr ds:[version],1d	; sprawdzam czy mam odszyfrować czy zaszyfrować tekst
			je cipher_version_1
			
			cipher_version_0:
				call cipher_char			; szyfrowanie znaku
				jmp cipher_done
			
			cipher_version_1:				; odszyfrowywanie znaku
				call decipher_char
			
			cipher_done:					; znak zeszyfrowany/odszyfrowany
			
			call putchar					; znak do bufora wyjściwego - znak w al
			
			mov ax,bx						; do ax pozycja znaku w kodzie
			inc ax 							; zwiększam ax - na następną pozycję
			div cl							; dzielę ax przez cl (ilość znaków kodu) - wynik w al, reszta w ah
			mov bl,ah						; do bl reszta z dzielenia
			mov bh,0						; zeruje bh - bx=bl
			
		jmp loop_cipher
		
		end_loop_cipher:					; koniec pliku
			call write_output_buffer		; zapisanie do pliku wyjściowego zawartości bufora
			
		
		end_cipher:
			pop ax
			ret
		
	cipher endp

;--------------------------------------------------------------------
;		cipher_char
;
;			wejście:
;				al - znak do zaszyfrowania
;				dx - znak kodu
;
;			wyjście:
;				al - zaszyfrowany znak
;			
;--------------------------------------------------------------------
	cipher_char proc

			mov ah,0						; zerowanie ah - al=ax
			add ax,dx						; do ax dodaję dx
			cmp ax,256d						; porównuję ax z 256d
			jb end_cipher_char				; jeśli mniejsze to ok
			
			sub ax,256d						; jeśli większe lub równe to muszę odjęć 256d
		
		end_cipher_char:
			ret
		
	cipher_char endp
	
;--------------------------------------------------------------------
;		decipher_char
;
;			wejście:
;				al - znak do odszyfrowania
;				dx - znak kodu
;
;			wyjście:
;				al - odszyfrowany znak
;			
;--------------------------------------------------------------------
	decipher_char proc

			mov ah,0						; zerowanie ah - al=ax
			cmp ax,dx						; porównuję znak do odszyfrowania ze znakiem kodu
			jae sub_decipher_char			; jeśli większy lub równy to wystarczy odjąć
			
			add ax,256d						; jeśli nie to do ax muszę dodać 256d - żeby kod znaku był większy od 0
			
			sub_decipher_char:
				sub ax,dx					; od ax odejmuję dx - od znaku do odszyfrowania kod znaku
		
		end_decipher_char:
			ret
		
	decipher_char endp
	
code1 ends
	

stos1 segment stack								;segment stosu
	dw 250 dup(?)
	w_stos dw ?
stos1 ends

end start