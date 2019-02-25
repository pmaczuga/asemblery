
dane1 segment
	arg db 200 dup('$')							; sparsowane argumenty odzielone znakiem $
	arg_l db 10 dup(0)							; tablica długości kolejnych argumentów
	arg_o dw 10 dup(?)							; tablica offsetów pierwszych znaków argumentów
	arg_n db 0									; ilość argumentów
	
	new_line db 13,10,"$"						; przejście do nowej linii 
dane1 ends


code1 segment
	start:
	
	mov ax,seg w_stos							;inicjalizacja stosu
	mov ss,ax
	mov sp,offset w_stos
	
	call parse
	call print
	
	
	end_program:								; koniec programu
		mov ah,4ch
		int 21h

;--------------------------------------------------------------------
;	Procedura:
;
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
			cmp cl,0							; sprawdzam czy skończyły się znaki w lini komend
			je end_parse						; jeśli tak kończę parsowanie
			
			call copy_argument					; procedura kopiująca kolejne znaki argumentu do pamięci
			inc di								; zwiększam di - po żeby po argumencie pojawił się znak $
			cmp cl,0							; znowu sprawdzam czy skończyły się znaki
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
;	Procedura:
;
;	first_not_white
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
		
			cmp cl,0							; sprawdzam czy koniec lini komend
			je end_first_not_white				; jeśli tak kończę procedurę
			
			mov al,es:[si]						; do al kod znaku

			dec cl								; zmniejszam cl o 1 - licznik znaków do końca linii
			inc si								; si - na następny znak

			cmp al,32d							; sprawdzam czy jest to spacja
			je loop_first_not_white				; jeśli tak przechodzę na początek pętli
			cmp al,9d							; jeśli nie sprawdzam czy jest to tab
			je loop_first_not_white	

		end_first_not_white:					; koniec procedury
			dec si 								; przesunęło się o jedną pozycję za daleko na końcu pętli
			inc cl								; tak jak si
			pop ax
			ret
			
	first_not_white endp
	
;--------------------------------------------------------------------
;	Procedura:
;
;	copy_argument
;		wejście:
;			es:[si] - pozycja początku nowego argumentu
;			ds:[di] - tu bedę wpisywał znaleziony argument
;			cl - ilość pozostałych znaków w lini komend
;		wyjście:
;			si - pozycja pierwszego białego znaku
;			di - wskazuje miejsce po ostatnim wpisanym znaku
;			cl - pozostałe znaki
;			argument umieszczony w odpowiednim miejscu w pamięci
;			długość argumentu umieszczona w odpowiedniej tablicy
;			offset początku argumentu do tablicy
;--------------------------------------------------------------------
	copy_argument proc
		push ax
		push bx
		
		mov bl,ds:[arg_n]						; do bl - numer argumentu
		mov bh,0								; zerowanie bh - żeby w bx było to samo co w bl
		shl bx,1								; przesuwam bx o jeden bit w lewo, czyli mnoże przez 2 - kolejne offsety w tablicy mają 2 bajty
		mov word ptr ds:[arg_o + bx],di			; od ds:[di] zacznę zapisywać argument, więc di kopiuję do tablicy offsetów
		mov ah,0								; ilość znaków argumentu - żeby długość argumentu zpisać do odpowiedniej tablicy
		
		loop_copy_argument:
		
			cmp cl,0							; sprawdzam czy koniec lini komend
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
;	Procedura:
;
;	print
;--------------------------------------------------------------------
	print proc
		push ax
		push bx
		push cx
		push dx
		
		mov bx,0								; w bx będzie numer argumentu*2 - potrzebne do tablicy offsetów
		mov cl,byte ptr ds:[arg_n]				; do cl ilość argumentów
		
		loop_print:
			cmp cl,0							; sprawdzam czy skończyły się argumenty do wypisania
			je end_print						; jeśli tak kończe wypisywanie
			
			mov dx,word ptr ds:[arg_o + bx]		; do dx offset następnego argumentu
			
			mov ah,9h							; wypisanie ciągu znaków z DS:[DX] - argumentu
			int 21h
			
			mov dx,offset new_line				; przejście do nowej linii
			mov ah,9h
			int 21h
			
			add bx,2							; zwiększam bx o 2 - offsety są 2-bajtowe
			
			dec cl
		jmp loop_print
		
		end_print:
			pop dx
			pop cx
			pop bx
			pop ax
			ret
	print endp
	
code1 ends
	
stos1 segment stack
	dw 250 dup(?)
	w_stos dw ?
stos1 ends

end start