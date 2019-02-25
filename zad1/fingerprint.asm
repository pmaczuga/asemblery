; Paweł Maczuga
; key fingerprint
; modyfikacja: odbijanie się od ścian


dane1 segment
	arg db 200 dup('$')							; sparsowane argumenty odzielone znakiem $
	arg_l db 10 dup(0)							; tablica długości kolejnych argumentów (l - length)
	arg_o dw 10 dup(?)							; tablica offsetów pierwszych znaków argumentów (o - offset)
	arg_n db 0									; ilość argumentów (n - number)
	
	bin db 16 dup(?)							; drugi argument przekonwertowany do postaci binarnej
	
	chess db 153 dup(0)							; szachownica 17x9 wypełniona zerami
	last_pos db ?								; ostatnia pozycja gońca - do wstawienia 'E' na szachownicy
	
	up_border db "+------ASCII------+",13,10,"$"	; górna granica szachownicy
	down_border db "+-----------------+",13,10,"$"	; dolna granica szachownicy
	char db ' ','.','o','+','=','*','B','O','X','@','%','&','#','/','^'	; tablica ze znakami do wypełnienia szachownicy
	
	new_line db 13,10,"$"						; przejście do nowej linii

;												; komunikaty o błędach
	error_wrong_amount_arguments db "Error. Zla liczba argumentow. Podaj 2",13,10,"$"
	error_wrong_size_1 db "Error. Pierwszy argument powinien miec 1 znak",13,10,"$"
	error_wrong_size_2 db "Error. Drugi argument powinien miec dokladnie 32 znaki",13,10,"$"
	error_wrong_1 db "Error. Pierwszy argument powinien byc 0 lub 1",13,10,"$"
	error_wrong_2 db "Error. Drugi argument powinien zawierac tylko znaki 0-9 i a-f",13,10,"$"
dane1 ends


code1 segment
	start:
	
	mov ax,seg w_stos							; inicjalizacja stosu
	mov ss,ax
	mov sp,offset w_stos
	
;-------------------------------------------------------------------------------------------------------------------------
;---------------------------------------POCZĄTEK-PROGRAMU-----------------------------------------------------------------	
	
	call parse									; parsowanie argumentów
	call check_arguments						; sprawdzanie poprawności argumentów
	call convert_arguments						; konwersja drugiego argumentu do postaci binarnej
	call fill_chess								; wypełnienie szachownicy liczbą odwiedzin gońca
	call fill_chess_ascii						; wypełnienie szachownicy odpowiednimi znakami ASCII
	call print_chess							; wydrukowanie szachownicy
	
	mov ah,4ch									; koniec programu
	int 21h

	
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
;		procedura sprawdzająca poprawność argumentów i wyświetlająca komunikaty o błedach
;--------------------------------------------------------------------
	check_arguments proc
		push ax
		push bx
		push cx
		
		cmp byte ptr ds:[arg_n],2d				; sprawdzam czy są 2 argumenty
		jne error1								; jeśli nie - skok do komunikatu z błędem
		
		cmp byte ptr ds:[arg_l],1d				; czy pierwszy argument ma 1 znak
		jne error2								; jeśli nie - skok do komunikatu z błędem
		cmp byte ptr ds:[arg_l+1],32d			; czy drugi argument ma 32 znaki
		jne error3								; jeśli nie - komunikat z błędem
	
		cmp byte ptr ds:[arg],49d				;czy pierszy argument jest jedynką
		ja error4
		cmp byte ptr ds:[arg],48d				;czy pierszy argument jest zerem
		jb error4
		
		
		mov bx,ds:[arg_o+2]						; do bx offset drugiego argumentu (offsety są 2-bajtowe, dlatego +2)
		mov cl,32d								; do cl długość drugiego argumentu - już wiem że jest to 32d
		
		loop_check_arguments:
			cmp cl,0							; sprawdzam czy sprawdzone zostały wszystkie znaki
			je end_check_arguments				; jeśli tak - sprawdzanie zakończone - skok do końca procedury
			
			mov al,byte ptr ds:[bx]				; do al kolejny znak drugiego argumentu
			
			cmp al,48d							; czy kod ASCII znaku jest mniejszy od 48d - '0'
			jb error5
			cmp al,58d							; porównuję z 58d - '9'
			jbe next_char						; jeśli mniejszy lub równy to znak jest z przedziału <0,9> czyli ok i sprawdzamy następny
			cmp al,97d							; jeśli większy sprawdzamy czy jest mniejszy od 97d, czyli 'a'
			jb error5							; jeśli nie to jest pomiędzy '9' i 'a', czyli błąd
			cmp al,102d							; sprawdzamy czy jest większy od 102 - 'f'
			ja error5							; jeśi tak - błąd
			
			next_char:							; jeśli doszedł tutaj znaczy że znak jest ok
				dec cl							; zmniejszam cl - licznik pozstałych znaków do sprawdzenia
				inc bx							; zwiększam bx - wskazanie na następny znak
		jmp loop_check_arguments				; kontynuajcja pętli
		
		jmp end_check_arguments					; skoro wyszedł z pętli to drugi argument jest ok - skok do końca procedury
	
		error1:									; Zła liczba argumentów
			mov dx,offset error_wrong_amount_arguments
			mov ah,9h
			int 21h
			mov ah,4ch
			int 21h
		error2:									; Za długi pierwszy argument
			mov dx,offset error_wrong_size_1
			mov ah,9h
			int 21h
			mov ah,4ch
			int 21h
		error3:									; Zła długość drugiego argumentu
			mov dx,offset error_wrong_size_2
			mov ah,9h
			int 21h
			mov ah,4ch
			int 21h
		error4:									; Niedozwolony znak w pierwszym argumencie
			mov dx,offset error_wrong_1
			mov ah,9h
			int 21h
			mov ah,4ch
			int 21h
		error5:									; Niedozwolony znak w drugim argumencie
			mov dx,offset error_wrong_2
			mov ah,9h
			int 21h
			mov ah,4ch
			int 21h
			
		end_check_arguments:
			pop cx
			pop bx
			pop ax
			ret
			
	check_arguments endp
	
;--------------------------------------------------------------------
;	convert_arguments
;
;		procedura konwertująca ciąg liczb w postaci szesnastkowej - drugi argument - do binarnej 
;		i zapisująca wynik do pamięci - tablicy bin
;--------------------------------------------------------------------
	convert_arguments proc
		push ax
		push cx
		push si
		push di
		
		mov cx,16								; 16 razy wykona się pętla
		
		mov si,offset arg						; do si offset z ciągiem argumentów
		add si,2								; dodaję 2 - na pierwszym miejscu flaga, na drugim $
		
		mov di,offset bin						; tu będę zapisywał ciąg binarny
		
		loop_convert_arguments:
		
			mov ah,byte ptr ds:[si]				; do ah pierwszy znak
			inc si								; si na drugi
			mov al,byte ptr ds:[si]				; do al drugi znak
			inc si								; si na następny znak
			
			call hex_to_bin						; konwersja dwóch znaków do postaci binarnej, wynik w al
			
			mov byte ptr ds:[di],al				; zapisuję bajt do pamięci
			inc di								; di na następną pozycję
			
		loop loop_convert_arguments				; zmniejszenie cx o 1, sprawdzenie czy nie jest zerem i skok na początek pętli
	
		end_convert_arguments:
			pop di
			pop si
			pop cx
			pop ax
			ret
	convert_arguments endp
	
;--------------------------------------------------------------------
;	hex_to_bin
;
;		wejście:
;			ah,al - dwa znaki liczby w postaci szesnastkowej
;		wyjście
;			al - liczba w postaci binarnej
;--------------------------------------------------------------------
	hex_to_bin proc
		push cx
		
		cmp al,57d								; Porównuję znka w al z 57d - '9'
		jbe bin_number_al						; jeśli jest mniejszy równy to jest to liczba <0-9>, skok w odpowiednie miejsce
		
		bin_char_al:							; jeśli nie jest to znak <a-f>
			sub al,87d							; w ah jest kod ASCII, czyli odejmuję 97d ('a'), a następnie dodaję 10, bo 0ah=10d
			jmp bin_ah							; omijajm bin_number_al
		bin_number_al:							; jeśli ah będzie z przedziału <0-9> wykona się to
			sub al,48d							; odejmuję od al 48d - '0'
			
		bin_ah:
		cmp ah,57d								; Porównuję znka w ah z 57d - '9'
		jbe bin_number_ah						; jeśli jest mniejszy równy to jest to liczba <0-9>
		
		bin_char_ah:							; jeśli nie jest to znak <a-f>
			sub ah,87d							; w ah jest kod ASCII, czyli odejmuję 97d ('a'), a następnie dodaję 10, bo 0ah=10d
			jmp bin_shift						; omijam bin_number_ah
		bin_number_ah:							; jeśli ah będzie z przedziału <0-9> skoczę tu
			sub ah,48d
			
		bin_shift:								; zapisanie wyniku do al
			mov cl,4d							; do cl 4 - nie mogę bezpośrednio napisać shl ah,4
			shl ah,cl							; przesuwam ah o 4 bity w lewo
			add al,ah							; a potem dodaję to do al
		
		end_hex_to_bin:
			pop cx
			ret
	hex_to_bin endp
	
;--------------------------------------------------------------------
;	fill_chess
;
;		procedura wypełniająca szachownice 17x9 liczbami odwiedzin gońca
;--------------------------------------------------------------------
	fill_chess proc
		push ax
		push bx
		push cx
		push si
		
		mov cx,16								; ilość wykonań głównej pętli
		
		mov si,76								; w si będzie aktualna pozycja gońca - na początku 76, czyli środek szachwnicy
		
		mov bx,0								; licznik ruchów - będzie pokazywał ile ruchów wykonał już goniec
		loop_fill_chess:
			push cx								; będę potrzebował cx, więc jego wartość odkładam na stos
			
			mov ah,byte ptr ds:[bin+bx]			; do ah kolejny bajt ciągu
			mov ch,4d							; ilość wykonań wewnętrznej pętli - bajt = 8 bitów, a ruch jest 2-bitowy
			mov cl,0							; o ile bitów przesunąć al, żeby pobierać kolejne 2-bitowe ruchy
			
			loop_single_byte:
				mov al,ah						; przenoszę bajt z ah do al - żeby nie modyfikować ah
				shr al,cl						; przesuwam bity w prawo o cl pozycji
				and al,00000011b				; w al zostają dwa najmłodsze bity
				
				call move_bishop				; idę gońcem na odpowiednie pole, ruch podany w al
				
				add cl,2d						; dodaje do cl 2 - następne przesunięcie przesunie na początek kolejne dwa bity
			
				dec ch							; zmniejszam ch o 1
				cmp ch,0						; porównuję z 0
			jne loop_single_byte				; i kontynuuję pętlę jeśli jest różne
		
			inc bx								; zwiększam bx o 1, żeby wziąć następny bajt z ds:[bin]
		
			pop cx								; pobieram ze stosu do cx
		loop loop_fill_chess					; zmniejszam o 1, porównuję z 0 i skaczę na początek pętli
		
		end_fill_chess:
			mov ax,si							; ostatnia pozycja gońca do ax
			mov byte ptr ds:[last_pos],al		; a potem do pamięci - szachownica ma 153 pola więc al = ax 
			
			pop si
			pop cx
			pop bx
			pop ax
			ret
	fill_chess endp
	
;--------------------------------------------------------------------
;	move_bishop
;
;		wejście:
;			al - kod ruchu
;			ds:[arg] - pierwszy bajt to flaga modyfikacji -  potrzebne dla procedur ruchu
;			si - aktualna pozycja gońca
;		wyjście:
;			si - nowa pozycja gońca
;			zwiększenie wartości odwiedzin w odpowiedniej tablicy
;
;		procedura dostająca kod ruchu i wywolująca odpowiednią proceudrę ruchu
;		
;--------------------------------------------------------------------
	move_bishop proc
		
		cmp al,00b								; sprawdzam czy kod ruchu to 00b
		jne next_move_1							; jeśli nie sprawdzam dalej
		call move_bishop_ul						; jeśli tak wykonuję ruch ul: up-left
		jmp end_move_bishop						; ruch wykonany, więc skaczę do końca procedury

		next_move_1:
		cmp al,01b								; analogicznie ja wyżej
		jne next_move_2
		call move_bishop_ur						; up-right
		jmp end_move_bishop
		
		next_move_2:
		cmp al,10b								; analogicznie jak wyżej
		jne next_move_3
		call move_bishop_dl						; down-left
		jmp end_move_bishop
		
		next_move_3:							; skoro nie był to 00b,01b ani 10b, to musi być to 11b
		call move_bishop_dr						; down-right
	
		end_move_bishop:
			inc byte ptr ds:[chess + si]		; zwiększam ilość odwiedzin na nowej pozycji gońca
			
			ret
	move_bishop endp
	
;--------------------------------------------------------------------
;	move_bishop_ul			up-left
;
;		wejście:
;			si - aktualna pozycja gońca
;		wyjście:
;			si - nowa pozycja gońca
;--------------------------------------------------------------------
	move_bishop_ul proc
		push ax
		push bx
		
		cmp si,17d								; sprawdzam czy goniec stoi na polu <= 17, czyli przy górnej granicy szachownicy
		jbe ul_up_wall							; jeśli tak skaczę do odpowieniego miejsca
		
		mov ax,si								; przenoszę pozycję gońca do ax
		
		mov bl,17d								; do bl 17d - nie mogę dzielić bezpośrenio
		div bl									; dzielę ax przez 17d, wynik dzielenia w al, reszta w ah
		cmp ah,0								; porównuję resztę z zerem, jeśli jest zerem to goniec jest przy lewej granicy szachownicy
		je ul_left_wall							; jeśli ah=0 skaczę do odpowiedniego miejsca
		
		sub si,18d								; jeśli doszedł tutaj, znaczy że jest gdzieś na środku, więc odejmuję od jego pozycji 18d
		jmp end_move_bishop_ul					; goniec się ruszył, więc kończę procedurę
		
		ul_up_wall:
			cmp si,0							; sprawdzam, czy nie jest w lewym górnym rogu
			je ul_corner						; jeśli tak skaczę do odpowiedniego  miejsca
			
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_ul_up_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			dec si								; jeśli flaga=0 goniec ślizga się po krawędzi o 1 w lewo
			jmp end_move_bishop_ul				; goniec się ruszył, więc kończę procedurę
			
			mod_ul_up_wall:
				add si,16d						; goniec odbija się od ściany w dół i lewo
				jmp end_move_bishop_ul			; goniec się ruszył, więc kończę procedurę
		
		ul_left_wall:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_ul_left_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			sub si,17d							; jeśli flaga=0 goniec ślizga się po ścianie o jedno pole w górę
			
			mod_ul_left_wall:
				sub si,16d						; goniec odbija się od ściany w górę i prawo
				jmp end_move_bishop_ul			; goniec się ruszył, więc kończę procedurę
				
		ul_corner:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_ul_corner					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie 
			
			jmp end_move_bishop_ul				; goniec stoi w miejscu - kończę procedurę
			
			mod_ul_corner:
				add si,18d						; goniec odbija się od rogu w dół i prawo
				jmp end_move_bishop_ul			; goniec się ruszył, więc kończę procedurę
		
		end_move_bishop_ul:
			pop bx
			pop ax
			ret
	move_bishop_ul endp
	
;--------------------------------------------------------------------
;	move_bishop_ur			up-right
;
;		wejście:
;			si - aktualna pozycja gońca
;		wyjście:
;			si - nowa pozycja gońca
;--------------------------------------------------------------------
	move_bishop_ur proc
		push ax
		push bx
		
		cmp si,17d								; sprawdzam czy goniec stoi na polu <= 17, czyli przy górnej granicy szachownicy
		jbe ur_up_wall							; jeśli tak skaczę do odpowieniego miejsca
		
		mov ax,si								; przenoszę pozycję gońca do ax
		
		mov bl,17d								; do bl 17d - nie mogę dzielić bezpośrenio
		div bl									; dzielę ax przez 17d, wynik dzielenia w al, reszta w ah
		cmp ah,16d								; porównuję resztę z 16d, jeśli jest równe 16d to goniec jest przy prawej granicy szachownicy
		je ur_right_wall						; jeśli ah=16d skaczę do odpowiedniego miejsca
		
		sub si,16d								; jeśli doszedł tutaj, znaczy że jest gdzieś na środku, więc odejmuję od jego pozycji 16d
		jmp end_move_bishop_ur					; goniec się ruszył, więc kończę procedurę
		
		ur_up_wall:
			cmp si,16							; sprawdzam, czy nie jest w prawym górnym rogu
			je ur_corner						; jeśli tak skaczę do odpowiedniego  miejsca
			
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_ur_up_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			inc si								; jeśli flaga=0 goniec ślizga się po krawędzi o 1 w prawo
			jmp end_move_bishop_ur				; goniec się ruszył, więc kończę procedurę
			
			mod_ur_up_wall:
				add si,18d						; goniec odbija się od ściany w dół i prawo
				jmp end_move_bishop_ur			; goniec się ruszył, więc kończę procedurę
		
		ur_right_wall:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_ur_left_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			sub si,17d							; jeśli flaga=0 goniec ślizga się po ścianie o jedno pole w górę
			
			mod_ur_left_wall:
				sub si,18d						; goniec odbija się od ściany w górę i lewo
				jmp end_move_bishop_ur			; goniec się ruszył, więc kończę procedurę
				
		ur_corner:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_ur_corner					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie 
			
			jmp end_move_bishop_ur				; goniec stoi w miejscu - kończę procedurę
			
			mod_ur_corner:
				add si,16d						; goniec odbija się od rogu w dół i lewo
				jmp end_move_bishop_ur			; goniec się ruszył, więc kończę procedurę
		
		end_move_bishop_ur:
			pop bx
			pop ax
			ret
	move_bishop_ur endp
	
;--------------------------------------------------------------------
;	move_bishop_dl			down-left
;
;		wejście:
;			si - aktualna pozycja gońca
;		wyjście:
;			si - nowa pozycja gońca
;--------------------------------------------------------------------
	move_bishop_dl proc
		push ax
		push bx
		
		cmp si,136d								; sprawdzam czy goniec stoi na polu >= 136, czyli przy dolnej granicy szachownicy
		jae dl_down_wall						; jeśli tak skaczę do odpowieniego miejsca
		
		mov ax,si								; przenoszę pozycję gońca do ax
		
		mov bl,17d								; do bl 17d - nie mogę dzielić bezpośrenio
		div bl									; dzielę ax przez 17d, wynik dzielenia w al, reszta w ah
		cmp ah,1								; porównuję resztę z zerem, jeśli jest zerem to goniec jest przy lewej granicy szachownicy
		je dl_left_wall							; jeśli ah=0 skaczę do odpowiedniego miejsca
		
		add si,16d								; jeśli doszedł tutaj, znaczy że jest gdzieś na środku, więc dodaję do jego pozycji 16d
		jmp end_move_bishop_dl					; goniec się ruszył, więc kończę procedurę
		
		dl_down_wall:
			cmp si,136d							; sprawdzam, czy nie jest w lewym dolnym rogu
			je dl_corner						; jeśli tak skaczę do odpowiedniego  miejsca
			
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_dl_down_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			dec si								; jeśli flaga=0 goniec ślizga się po krawędzi o 1 w lewo
			jmp end_move_bishop_dl				; goniec się ruszył, więc kończę procedurę
			
			mod_dl_down_wall:
				sub si,18d						; goniec odbija się od ściany w górę i lewo
				jmp end_move_bishop_dl			; goniec się ruszył, więc kończę procedurę
		
		dl_left_wall:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_dl_left_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			add si,17d							; jeśli flaga=0 goniec ślizga się po ścianie o jedno pole w dół
			
			mod_dl_left_wall:
				add si,18d						; goniec odbija się od ściany w dół i prawo
				jmp end_move_bishop_dl			; goniec się ruszył, więc kończę procedurę
				
		dl_corner:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_dl_corner					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie 
			
			jmp end_move_bishop_dl				; goniec stoi w miejscu - kończę procedurę
			
			mod_dl_corner:
				sub si,16d						; goniec odbija się od rogu w górę i prawo
				jmp end_move_bishop_dl			; goniec się ruszył, więc kończę procedurę
		
		end_move_bishop_dl:
			pop bx
			pop ax
			ret
	move_bishop_dl endp

;--------------------------------------------------------------------
;	move_bishop_dr			down-right
;
;		wejście:
;			si - aktualna pozycja gońca
;		wyjście:
;			si - nowa pozycja gońca
;--------------------------------------------------------------------
	move_bishop_dr proc
		push ax
		push bx
		
		cmp si,136d								; sprawdzam czy goniec stoi na polu >= 136, czyli przy dolnej granicy szachownicy
		jae dr_down_wall						; jeśli tak skaczę do odpowieniego miejsca
		
		mov ax,si								; przenoszę pozycję gońca do ax
		
		mov bl,17d								; do bl 17d - nie mogę dzielić bezpośrenio
		div bl									; dzielę ax przez 17d, wynik dzielenia w al, reszta w ah
		cmp ah,16d								; porównuję resztę z 16d, jeśli jest równe 16d to goniec jest przy prawej granicy szachownicy
		je dr_right_wall						; jeśli ah=16d skaczę do odpowiedniego miejsca
		
		add si,18d								; jeśli doszedł tutaj, znaczy że jest gdzieś na środku, więc dodaję do jego pozycji 18d
		jmp end_move_bishop_dr					; goniec się ruszył, więc kończę procedurę
		
		dr_down_wall:
			cmp si,152d							; sprawdzam, czy nie jest w prawym dolnym rogu
			je dr_corner						; jeśli tak skaczę do odpowiedniego  miejsca
			
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_dr_down_wall					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			inc si								; jeśli flaga=0 goniec ślizga się po krawędzi o 1 w prawo
			jmp end_move_bishop_dr				; goniec się ruszył, więc kończę procedurę
			
			mod_dr_down_wall:
				sub si,16d						; goniec odbija się od ściany w górę i prawo
				jmp end_move_bishop_dr			; goniec się ruszył, więc kończę procedurę
		
		dr_right_wall:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_dr_right_wall				; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie
			
			add si,17d							; jeśli flaga=0 goniec ślizga się po ścianie o jedno pole w dół
			
			mod_dr_right_wall:
				add si,16d						; goniec odbija się od ściany w dół i lewo
				jmp end_move_bishop_dr			; goniec się ruszył, więc kończę procedurę
				
		dr_corner:
			cmp byte ptr ds:[arg],49d			; sprawdzam flagę modyfikacji
			je mod_dr_corner					; jeśli jest równa 1, wykonuję zmodyfikowany ruch - odbicie 
			
			jmp end_move_bishop_dr				; goniec stoi w miejscu - kończę procedurę
			
			mod_dr_corner:
				sub si,18d						; goniec odbija się od rogu w górę i lewo
				jmp end_move_bishop_dr			; goniec się ruszył, więc kończę procedurę
		
		end_move_bishop_dr:
			pop bx
			pop ax
			ret
	move_bishop_dr endp
	
;--------------------------------------------------------------------
;	fill_chess_ascii
;
;		wejście: 
;			chess - tablica z ilościami odwiedzin gońca na każdym polu
;		wyjście:
;			chess - tablica z odpowienimi znakami ASCII
;
;		procedura zmienijąca liczbę odwiedzin gońca na odpowieni kod znaku ASCII
;--------------------------------------------------------------------	
	fill_chess_ascii proc
		push ax
		push bx
		push cx
		push dx
		push si
		push di
		
		mov di,offset chess						; di bedzie chodził po szachownicy
		mov si,offset char						; si będzie wskazywał na tablice znaków do wklejenia - char
		mov cx,153d								; pętla wykona się 153 razy - ilość pól szachownicy
		
		loop_fill_chess_ascii:
			mov bh,0							; zeruję bh, żeby bl=bx
			mov bl,byte ptr ds:[di]				; do bl liczba odwiedzin gońca dla danego pola
			cmp bx,14d							; porównuję z 14d
			jb fill								; jeśli mniejsze od 14d nic nie rób
			mov bx,14d							; jeśli większe zamień na 14d
			
			fill:
				mov al,byte ptr ds:[si + bx]	; do al znak do wklejenia
				mov byte ptr ds:[di],al			; a potem do szachownicy - nie mogę bezpośrenio
		
		inc di									; di na następnę pozycję
		loop loop_fill_chess_ascii				; zmniejsz cx, porównaj z zerem, kontynuuj pętlę
		
		mov di,offset chess						; do di jeszcze raz offset początku tablicy chess
		mov bx,76d								; do bx środek szachownicy
		mov al,'S'								; do al znak 'S' - rozpoczęcie ruchu gońca
		mov byte ptr ds:[di+bx],al				; a potem do szachownicy

		mov bh,0								; zerwowanie bh -> bx=bl
		mov bl,byte ptr ds:[last_pos]			; do bx ostatnia pozycja gońca - bx - 2 bajtowe, last_poz - 1 bajtowe
		mov al,'E'								; do al 'E' - koniec ruchu gońca
		mov byte ptr ds:[di+bx],al				; a potem do szachownicy
		
		end_fill_chess_ascii:
			pop di
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
			ret
	fill_chess_ascii endp
	
;--------------------------------------------------------------------
;	print_chess
;
;		procedura wyświetlająca szachwonicę chess na ekranie
;--------------------------------------------------------------------	
	print_chess proc
		push ax
		push bx
		push cx
		push dx
		
		mov bx,offset chess						; bx będzie chodził po szachownicy
		
		mov dx,offset up_border					; wypisanie górnej granicy
		mov ah,9h
		int 21h
		
		mov cl,9								; szachownica ma 9 wierszy
		loop_print_chess:						; pierwsza pętla idąca po wierszach
			
			mov dl,'|'							; do dl znak '|' - lewa granica
			mov ah,2h							; wypisz znak z dl
			int 21h
			
			mov ch,17							; szachownica ma 17 kolumn
			loop_print_chess_2:					; druga pętla idąca po kolumnach
				
				mov dl,ds:[bx]					; do dl znak z odpowiedniego pola szachownicy
				mov ah,2h						; wypisz znak z dl
				int 21h
				
				inc bx							; bx na następne pole
				
				dec ch							; zmniejszenie ch
				cmp ch,0						; porównianie z 0
			jne loop_print_chess_2				; kontynuacja pętli
			
			mov dl,'|'							; wypisz znak '|' - prawa granica
			mov ah,2h
			int 21h
			
			mov dx,offset new_line				; przejście do nowej linii
			mov ah,9h
			int 21h
			
			dec cl								; zmniejszenie cl
			cmp cl,0							; porównianie z 0
		jne loop_print_chess					; kontynuacja pętli
		
		mov dx,offset down_border				; wypisanie dolnej granicy
		mov ah,9h
		int 21h
		
		end_print_chess:
			pop dx
			pop cx
			pop bx
			pop ax
			ret
	print_chess endp
	
	
code1 ends
	

stos1 segment stack								;segment stosu
	dw 250 dup(?)
	w_stos dw ?
stos1 ends

end start