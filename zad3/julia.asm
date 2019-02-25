; Paweł Maczuga
; Zbiór Julii

dane1 segment
	arg db 200 dup('$')							; sparsowane argumenty odzielone znakiem $
	arg_l db 10 dup(0)							; tablica długości kolejnych argumentów (l - length)
	arg_o dw 10 dup(?)							; tablica offsetów pierwszych znaków argumentów (o - offset)
	arg_n db 0									; ilość argumentów (n - number)
	
	new_line db 13,10,"$"						; przejście do nowej linii
	
	int_before_dot dw 0							; zmienna, w której będą przechowywane warotści całkowite argumentów na czas ich konwersji
	int_after_dot dw 0							; zmienna, w której będą przechowywane warotści ułamkowe argumentów na czas ich konwersji
	sign db ?									; znak aktulanie konwertowanego argumentu
	int_after_dot_len db 0						; długość części ułamkowej - ile razy trzeba podzielić przez 10
	
	ten dw 10d									; do dzielenia przez 10 części ułamkowej konwertowanego argumentu
	four dw 4									; potrzebne w zbiorze Julii
	two dw 2									; potrzebne w zbiorze Julii
	
	xmin dq ?									; argumenty po konwersji
	xmax dq ?
	ymin dq ?
	ymax dq ?
	cr dq ?
	ci dq ?
	
	screen_width dw ?
	screen_length dw ?
	
	;punkt
	x dw ?
	y dw ?
	color db ?

;												; komunikaty o błędach
	error_number_of_arguments db "Error. Zla liczba argumentow. Podaj 6",13,10,"$"
	error_in_argument	db "Error. Bledne argumenty. Powinny byc w postaci 1.0 z lub ze znakiem +/- 1.0",13,10,"$"
	
	
dane1 ends

;-------------------------------------------------------------------------------------------------------------------------
;---------------------------------------SEGMENT-KODU----------------------------------------------------------------------
code1 segment
	start:
	.386
	.387
	
	mov ax,seg w_stos							; inicjalizacja stosu
	mov ss,ax
	mov sp,offset w_stos
	
	finit										; inicjalizacja koprocesora
	
;-------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------MAKRA-------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------


	exit macro									; makro kończące program
		mov ah,4ch
		int 21h
	endm
	
	enter_VGA macro
		mov al,13h								; tryp graficzny 320x200, 256 kolorów
		mov ah,0
		int 10h
		
		mov word ptr ds:[screen_width],320		; szerokość
		mov word ptr ds:[screen_length],200		; i dłuogść ekranu do pamięci
		
		mov ax,0a000h							; segment z VGA
		mov es,ax
	endm
	
	exit_VGA macro
		mov al,3								; przejście do trybu tekstowego
		mov ah,0
		int 10h
	endm
	
	press_key macro								; czekaj na wciśnięcie klawisza
		mov ah,0h
		int 16h
	endm
	
	print_string macro							; makro wypisujące napis z ds:dx
		push ax
		mov ah,9h
		int 21h
		pop ax
	endm
	
	print_char macro
		push ax
		mov ah,2d
		int 21h
		pop ax
	endm
	
	error1 macro								; Błąd 1 - zła liczba argumentów
		mov dx,offset error_number_of_arguments
		print_string
		exit
	endm
	
	error2 macro								; Błąd 2 - błędne argumenty
		mov dx,offset error_in_argument
		print_string
		exit
	endm
	
	
;-------------------------------------------------------------------------------------------------------------------------
;---------------------------------------POCZĄTEK-PROGRAMU-----------------------------------------------------------------	
	
	call parse									; parsowanie argumentów
	call check_arguments						; procedura sprawdzająca poprawność argumentów
	enter_VGA									; tryb graficzny
	call julia									; właściwa procedura wypisująca zbiór Julii
	press_key									; oczekiwanie na wciścnięcie klawisza
	exit_VGA									; wyjście z trybu graficznego
	
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
;		kolejność: xmin xmax ymin ymax cr ci
;--------------------------------------------------------------------
	check_arguments proc
		push bx
		push cx
		push si
		push di
		
		cmp byte ptr ds:[arg_n],6d					; sprawdzam czy jest 6 argumentów
		jne error_check_arguments
	
		mov bx,0									; bx=0, w bx będzie numer argumentu
		
		mov cl,byte ptr ds:[arg_l+bx]				; do cl długość argumentu
		mov si,word ptr ds:[arg_o+bx]				; do si offset argumentu
		mov di,offset xmin							; do di offset miejsca do zapisu
		call string_to_double						; procedura konwertująca argument z si o długości cl do di
		inc bx
		
		mov cl,byte ptr ds:[arg_l+bx]
		shl bx,1									; offsety są 2-bajtowe
		mov si,word ptr ds:[arg_o+bx]
		shr bx,1									; a długości 1-bajtowe
		mov di,offset xmax
		call string_to_double
		inc bx
	
		mov cl,byte ptr ds:[arg_l+bx]
		shl bx,1
		mov si,word ptr ds:[arg_o+bx]
		shr bx,1
		mov di,offset ymin
		call string_to_double
		inc bx
	
		mov cl,byte ptr ds:[arg_l+bx]
		shl bx,1
		mov si,word ptr ds:[arg_o+bx]
		shr bx,1
		mov di,offset ymax
		call string_to_double
		inc bx
		
		mov cl,byte ptr ds:[arg_l+bx]
		shl bx,1
		mov si,word ptr ds:[arg_o+bx]
		shr bx,1
		mov di,offset cr
		call string_to_double
		inc bx
		
		mov cl,byte ptr ds:[arg_l+bx]
		shl bx,1
		mov si,word ptr ds:[arg_o+bx]
		shr bx,1
		mov di,offset ci
		call string_to_double
	
		jmp end_check_arguments
	
		error_check_arguments:
			error1
	
		end_check_arguments:
			pop di
			pop si
			pop cx
			pop bx
			ret
		
	check_arguments endp
	
;--------------------------------------------------------------------
;	string_to_double
;
;		wejście:
;			si - offset argumentu do skopiowania
;			cl - długość argumentu
;			di - offset miejsca w pamięci do zapisania argumentu
;
;		wyjście:
;			di - zapisany argument po konwersji
;
;		procedura konwertująca string na doulbe i zapisująca do pamięci
;		oraz sprawdzająca ich poprawność
;--------------------------------------------------------------------
	string_to_double proc
		push ax
		push bx
		push cx
		push dx
	
		mov bx,0								; bx=0, w bx będzie numer znaku do sprawdzenia
		mov byte ptr ds:[sign],0				; flaga sign = 0 - argument dodatni
		mov ax,0								; w ax będzie aktualnie konwertowana liczba
		
		cmp cl,3d								; sprawdzam czy długość argumentu to co najmniej 3
		jb error_wrong_argument
		
		minus_string_to_double:
			cmp byte ptr ds:[si+bx],45d			; porównanie znaku z 45d - "-"
			jne plus_string_to_double
			mov byte ptr ds:[sign],1			; flaga sign = 1 - argument ujemny
			inc bx								; bx na następną pozycję
			dec cl
			jmp first_dot_string_to_double
		
		plus_string_to_double:
			cmp byte ptr ds:[si+bx],43d			; porównanie znaku z 43d - "+"
			jne first_dot_string_to_double
			inc bx
			dec cl
			
		first_dot_string_to_double:				; sprawdzam czy jest część całkowita
			cmp byte ptr ds:[si+bx],46d			; porównanie znaku z 46d - "."
			je error_wrong_argument
			
		
		loop_before_dot_string_to_double:
			mov dx,0							; zeruję dx
			mov dl,byte ptr ds:[si+bx]			; w dl - aktualnie przetwarzany znak
			

			cmp dl,46d							; porównanie znaku z 46d - "."
			je dot_string_to_double				; jeśli równe - kropka - koniec części całkowitej
			cmp dl,48d							; porównanie znaku z 48d - "0"
			jb error_wrong_argument
			cmp dl,57d							; porównanie z 57d - "9"
			ja error_wrong_argument
			
			sub dl,48d							; żeby dl było w przedziale <0,9>
			
			push dx
			mov dx,10h
			mul dx								; mnożę ax przez dx - wynik w dx:ax - zakładam, że liczba zmieści się w ax
			pop dx
			add ax,dx							; w dl jest aktualna cyfra, dh=0
			
			inc bx
			dec cl
			cmp cl,0
		jne loop_before_dot_string_to_double
		
		jmp error_wrong_argument				; koniec argumentu, nie napotkano kropki - błąd
		
		dot_string_to_double:
			mov word ptr ds:[int_before_dot],ax	; część całkowita argumentu do pamięci
			mov byte ptr ds:[int_after_dot_len],0	; zerwowanie długości części ułamkowej
			mov ax,0d
			inc bx
			dec cl
			cmp cl,0							; sprawdzam, czy jest coś po kropce
			je error_wrong_argument
			
			
		loop_after_dot_string_to_double:
			mov dx,0							; zeruję dx
			mov dl,byte ptr ds:[si+bx]			; w dl - aktualnie przetwarzany znak
			
			cmp dl,48d							; porównanie znaku z 48d - "0"
			jb error_wrong_argument
			cmp dl,57d							; porównanie z 57d - "9"
			ja error_wrong_argument
			
			sub dl,48d							; żeby dl było w przedziale <0,9>
			
			push dx
			mov dx,10d
			mul dx								; mnożę ax przez dx - wynik w dx:ax - zakładam, że liczba zmieści się w ax
			pop dx
			add ax,dx							; w dl jest aktualna cyfra, dh=0
			
			inc byte ptr ds:[int_after_dot_len]	; zwiększam długość części ułamkowej
			inc bx
			dec cl
			cmp cl,0
		jne loop_after_dot_string_to_double
		
		mov word ptr ds:[int_after_dot],ax		; część ułamkowa argumentu do pamięci
		
		fild word ptr ds:[int_before_dot]		; sp(2)
		fild word ptr ds:[int_after_dot]		; sp(1)
		fild word ptr ds:[ten]					; sp(0)
		
		mov cl,byte ptr ds:[int_after_dot_len]	; do cl długość części ułamkowej
		loop_fraction_string_to_double:			; zamiana części ułamkowej "x" z "x.0" do "0.x"
			fdiv st(1),st(0)					; dzielę część ułamkową przez 10
			dec cl
			cmp cl,0
		jne loop_fraction_string_to_double
		fstp st									; st(0) - część ułamkowa, st(1) - część całkowita
		faddp st(1),st(0)						; dodanie st(1) i st(0) i zdjęcie ze stosu
		
		cmp ds:[sign],0							; sprawdzam czy liczba jest dodatnia
		je memorize_string_to_double
		fchs									; jeśli nie zamiana znaku st(0)
		
		memorize_string_to_double:
			fstp qword ptr ds:[di]				; zapisanie wyniku do pamięci i zdjęcie ze stosu
			jmp end_string_to_double
		
		error_wrong_argument:
			error2								; makro z błędem
		
		end_string_to_double:
			pop dx
			pop cx
			pop bx
			pop ax
			ret
		
	string_to_double endp
	
;--------------------------------------------------------------------
;	print_point
;
;		wejście:
;			es - segment pamięci VGA
;
;		procedura drukująca punkt o współrzędnych [x],[y] w kolorze [color]
;--------------------------------------------------------------------
	print_point proc
		push ax
		push bx
		push dx
		
		mov dx,word ptr ds:[screen_width]		; do dx szerokość ekranu
		mov ax,word ptr ds:[y]					; do ax współrzędna y
		mul dx									; dx:ax = ax*dx, czyli ax = screen_width*y, dx=0
		mov bx,word ptr ds:[x]					; do bx współrzędna x
		add bx,ax								; bx = screen_width*y + x
		mov al,byte ptr ds:[color]				; do al liczba określjąca kolor
		mov byte ptr es:[bx],al					; wartość koloru do segmentu VGA, na pozycje (x,y)
		
		end_print_point:
			pop dx
			pop bx
			pop ax
			ret
		
	print_point endp	

	
;--------------------------------------------------------------------
;	julia
;
;		procedura rysująca zbiór Julii
;--------------------------------------------------------------------
	julia proc
		push bx
		push cx
		
		mov byte ptr ds:[color],15d				; piksele będą kolorowane na biało
		
		fld qword ptr ds:[cr]					; st(1)
		fld qword ptr ds:[ci]					; st(0)
		
		mov cx,0d
		loop_1_julia:							; zewnętrzna pętla - po współrzędnych x
		
			mov bx,0d
			loop_2_julia:						; wewnętrzna pętla - po y
					mov word ptr ds:[x],cx		; x do pamięci
					mov word ptr ds:[y],bx		; y do pamięci
					
					fld qword ptr ds:[xmin]
					fild word ptr ds:[x]
					fld qword ptr ds:[xmax]
					fld qword ptr ds:[xmin]
					fsubp st(1),st(0)
					fild word ptr ds:[screen_width]
					fdivp st(1),st(0)
					fmulp st(1),st(0)
					faddp st(1),st(0)
					;       RPN:     xmin x xmax xmin - screen_width / * +
					
					fld qword ptr ds:[ymin]
					fild word ptr ds:[y]
					fld qword ptr ds:[ymax]
					fld qword ptr ds:[ymin]
					fsubp st(1),st(0)
					fild word ptr ds:[screen_length]
					fdivp st(1),st(0)
					fmulp st(1),st(0)
					faddp st(1),st(0)
					;       RPN:     ymin y ymax ymin - screen_length / * +
					
					;st(0)=y   st(1)=x   st(2)=ci   st(3)=cr
					call julia_color			; procedura kolorująca piksel na podstawie algorytmu Julii
					
				inc bx
				cmp bx,word ptr ds:[screen_length]
			jne loop_2_julia
			
			inc cx
			cmp cx,word ptr ds:[screen_width]
		jne loop_1_julia
	
		end_julia:
			pop cx
			pop bx
			ret
	
	julia endp	
	
;--------------------------------------------------------------------
;	julia_color
;
;		wejście:
;			st(0)=y   st(1)=x   st(2)=ci   st(3)=cr
;
;		wyjście:
;			st(0)=ci   st(1)=cr
;			pokolorowany punkt
;
;		procedura kolorująca punkt na podstawie algorytmu julii
;--------------------------------------------------------------------
	julia_color proc
		push ax
		push cx
		
		mov cx,1000d
		loop_julia_color:
			
			fld st(1)							; st(0)=x   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			fmul st(0),st(2)					; st(0)=x*x   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			fld st(1)							; st(0)=y   st(1)=x*x   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			fmul st(0),st(2)					; st(0)=y*y   st(1)=x*x   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			fsubp st(1),st(0)					; st(0)=x*x-y*y   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			fadd st(0),st(4)					; st(0)=x*x-y*y+cr   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			
			fild word ptr ds:[two]				; st(0)=2.0   st(1)=x*x-y*y+cr   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr				
			fmul st(0),st(3)					; st(0)=2*x   st(1)=x*x-y*y+cr   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			fmul st(0),st(2)					; st(0)=2*x*y   st(1)=x*x-y*y+cr   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			fadd st(0),st(4)					; st(0)=2*x*y+ci   st(1)=x*x-y*y+cr   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			
			fxch st(2)							; st(0)=y   st(1)=x*x-y*y+cr   st(2)=2*x*y+ci   st(3)=x   st(4)=ci   st(5)=cr
			fstp st(0)							; st(0)=x*x-y*y+cr   st(1)=2*x*y+ci   st(2)=x   st(3)=ci   st(4)=cr
			fxch st(2)							; st(0)=x   st(1)=2*x*y+ci   st(2)=x*x-y*y+cr   st(3)=ci   st(4)=cr
			fstp st(0)							; st(0)=2*x*y+ci   st(1)=x*x-y*y+cr   st(2)=ci   st(3)=cr				
			
												; x = x*x-y*y+cr
												; y = 2*x*y+ci
												; st(0)=y   st(1)=x   st(2)=ci   st(3)=cr
			
			fld st(1)							; st(0)=x   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			fmul st(0),st(2)					; st(0)=x*x   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			fld st(1)							; st(0)=y   st(1)=x*x   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			fmul st(0),st(2)					; st(0)=y*y   st(1)=x*x   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			faddp st(1),st(0)					; st(0)=x*x+y*y   st(1)=y   st(2)=x   st(3)=ci   st(4)=cr
			
			fild word ptr ds:[four]				; st(0)=4.0   st(1)=x*x+y*y   st(2)=y   st(3)=x   st(4)=ci   st(5)=cr
			fcomp								; porównanie st(0) z st(1) i zdjęcie ze stosu
			fstsw ax
			sahf
			jb colorize_julia_color				; jeśli 4.0 > x*x+y*y, to skok
			fstp st(0)							; st(0)=y   st(1)=x   st(2)=ci   st(3)=cr
			
		loop loop_julia_color
		
		mov ds:[color],0d
		jmp end_julia_color
		
		colorize_julia_color:
			fstp st(0)
			mov ds:[color],15d
			
			call print_point
		
		end_julia_color:
			fstp st(0)
			fstp st(0)
			; st(0)=ci   st(1)=cr
		
			pop cx
			pop ax
			ret
	
	julia_color endp	
	
	
code1 ends
	

stos1 segment stack								;segment stosu
	dw 250 dup(?)
	w_stos dw ?
stos1 ends

end start