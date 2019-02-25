## Zadanie 1 - zajęcia 1 i 2
## _Prezentacja funckji skrótu klucza publicznego (ang. key fingerprint) w postaci grafiki ASCII_

### Cel ćwiczenia

Celem zadania realizowanego w trakcie dwóch pierwszych spotkań laboratoryjnych jest zaznajomienie studentów z podstawowymi aspektami asemblera 8086, a w szczególności: dostępnymi rejestrami mikroprocesora i ich funkcją, segmentami pamięci operacyjnej i sopsobami jej adresacji metodami konstrukcją pętli i instrukcji sterujących za pomocą skoków warunkowych, instrukcjami operatorów logicznych, przesunięć bitowych i operatorów arytmetycznych, a także funcjami przerwania 21h realizującymi wejście z klawiatury i wyjście tekstowe na ekran.

### Zadanie

W ramach pierwszego zadania studenci zaimplementują program realizujący prostą grafikę ASCII. W szczególności, program ten będzie prezentował jako ASCII-art skróty kluczy publicznych (_key fingerprint_). Studenci zaznajomieni z współczesną dystrybucję Linuxa zapewne spotkali się już z takim sposobem "wyrażania" kluczy publicznych w pakiecie OpenSSH

```
The authenticity of host '149.156.87.95' (149.156.87.95)' can't be established. 
RSA key fingerprint is d5:29:3e:9a:8d:90:26:5d:6b:6b:fb:8a:bb:a5:da:23.
+--[ RSA 1024]----+
|                 |
|           . .   |
|        . o o    |  
|     . o + .     |
|    . = S o      |
|     o o * .     |
|        B .      |
|    E..= .       |
|    .o*+oo.      |
+-----------------|
Are you sure you want to continue conecting (yes/no)? █
```

Stworzony przez studentów program powinien wczytać z argumentu wywołania skrót klucza publicznego. Skrót taki składa się z 16 bajtów w zapisie heksadecymalnym.  
Przykład:  
fc94b0c1e5b0987c5843997697ee96b7

Po wczytaniu, skrót należy przekonwertować z zapisu heksadecymalnego do tablicy 16 bajtów a następnie przekształcić na ASCII-Art (algorytm konwersji podano w dalszej części instrukcji). Uzyskany ASCII-Art należy wypisać na ekran.

Implementacja rozwiązania zadania 1 powinna obejmować:
1. weryfikacje wprowadzonego skrótu pod kątem jego długości (32 znaki) i poprawności zapisu w kodzie szesnastkowym (alfabet złożony ze znaków 0-9a-f),
2. konwersję tego ciągu bajtów w zapisie heksadecymalnym do postaci binarnej,
3. konstrukcję ASCII-art na podstawie binarnej reprezentacji skrótu,
4. wyświetlenie stworzonej grafiki ASCII na ekranie.

Na ocenę rozwiązania zadania składa się:
1. poprawność implementacji, z uwzględnieniem wymienionych wyżej wymagań,
2. przejrzystość implementacji, w tym należyte skomentowanie poszczególnych partii instrukcji w programie, unikanie nadmiarowych/nieczytalnych instrukcji skoku oraz prawidłowy podział programu na podprocedury,
3. terminowość realizacji.

### Algorytm konstrukcji ASCII-Art

W artykule: http://www.dirk-loss.de/sshvis/drunken_bishop.pdf Studenci znajdą graficzną prezentację algorytmu konstrukcji ASCII-Art ze skrótu klucza publicznego.

Zakładamy, że dysponujemy szachowniczą o rozmiarze 17x9 pól. Pola ponumerowane są od 0 do 152. Na polu 76 (środek szachownicy) znajduje się goniec. Goniec analizuje kolejne bajty skrótu klucza, wkierunku od najstarszego do najmłodszego. W każdym bajcie goniec analizuje pary bitów, w kierunky od najmłodszej do najstarszej.

Każda kombinacja dwóch bitów reprezentuje ruch gońca na szachownicy. I tak, para 00 to ruch na szachownicy o jedno pole w lewo i jedno pole do góry. Para 01 to ruch o jedno pole w prawo i jedno do góry. Para 10 reprezentuje ruch o jedno pole w lewo i jedno pole w dół. Wreszcie, para 11 odpowiada ruchowi o jedno pole w prawo i jedno pole w dół. Jeśli goniec jest przy krawędzi szachownicy to nie wychodzi poza nią, lecz "ślizga" się po jej boku. W przypadku, gdy goniec znajduje się w narożniku szachownicy a analizowana para bitów wskazuje na ruch poza narożnik, goniec nie wykona ruchu.

Przechodząc przez szachownicę goniec zapamiętuje ile razy znajdował się na każdym z pól. Po zakończeniu ruchu gońca w pola szachownicy wstawiane są symbole ASCII. To jaki symblo zostanie wstawiony w dane pole, zależy od tego ile tazy w polu tym gościł goniec. I tak, jeśli dane pole nigdy nie było odwiedzone przez gońca nie wstawia się w nie żadnego symblolu. Jeśli było odwiedzone 1 raz, wstawiana jest kropka, w pola odwiedzone dwa razy wstawiana jest mała litera "o"... w sumie w polu można umieścić jeden z 14 następujących znaków ASCII:

| Liczba odwiedzin |1|2|3|4|5 |6|7|8|9|10|11|12|13|14|
|------------------|-|-|-|-|--|-|-|-|-|--|--|--|--|--|
| Znak ASCII       |.|o|+|=|\*|B|O|X|@|% |& |# |/ |^ |

Jeśli dane pole było odwiedzone więcej niż 14 razy, wstawiamy jest w nie znak "^". Dodatkowo, w polu, w którym goniec rozpoczął ruch wstawian jest litera S, zaś w polu, w którym ruch zakończył wstawiana jest litera E.

Po wstawieniu odpowiednich symboli, szachownica reprezentuje ASCII-Art dla zadanego skrótu klucza publicznego.
