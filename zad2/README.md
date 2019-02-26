## Zadanie 2 - zajęcia 3 i 4

## _Operacje na plikach; praca z napisami._

### Cel ćwiczenia

Celem zadania realizowanego w trakcie trzeciego i czwartego laboratorium jest zaznajomienie studentów z funkcjami przerwania 21h realizującymi operacje wejścia/wyjścia na plikach oraz z przetwarzaniem napisów w asemblerze.

### Zadanie

W ramach zadania 2 studenci zaimplementują program wczytujący zawartość pliku wejściowego, dokonujący na niej określonej operacji (szczegóły w kolejnym podpunkcie instrukcji) i zapisujący rezultat do pliku wynikowego. Nazwy plików wejściowego i wyjściowego, jak również ewentualne inne parametry, są przekazywane w linii poleceń programu.

Implementacja rozwiązania zadania 2 powinna obejmować weryfikację poprawności parametrów przekazanych w linii poleceń. Pliki wskazane w parametrach należy otwierać odpowiednio w trybie do odczytu (plik wejściowy) lub do zapisu (plik wyjściowy). Należy również uwzględnić obsługę błędów, które mogą zostać zgłoszone przez przerwanie 21h w trakcie realizacji operacji na plikach.

W pełni prawidłowe rozwiązanie powinno umożliwiać pracę z plikami o dowolnym rozmiarze. Proszę jednak zwrócić uwagę, że wczytytanie / zapisywanie plików znak po znaku jest niewydajne. Z tego powodu pliki powinne być wczytywane, przetwarzane oraz (jeśli to konieczne) zpisywane porcjami, np. po 16 kilobajtów. Można w tym celu zaimplementować proste funkcje buforujące, np. ```getchar``` / ```putchar```. Funkcja zwracająca poszczególne znaki z tego bufora. Po wczytaniu znaków w buforze funkcja powinna wczytać kolejną partię pliku. W analogiczny sposób można zaimplementować funkcję zapisującą (```putchar```) - funkjca ta umieszcza znaki w buforze, który jest fizycznie zapisywany do pliku, gdy zabraknie w niem miejsca na kolejny znak (oraz tuż przed zakończeniem programu).

Na ocenę rozwiązania zadania składają się:
1. poprawność implementacji - z uwzględnieniem wymienionych powyżej elementów składowych rozwiązania zadania,
2. przejrzystość implementacji, w tym należyte skomentowanie poszczególncyh partii instrukcji w programi, unikanie nadmiarowych / nieczytelnych instrukcji skoku oraz prawidłowy podział programu na procedury,
3. terminowość realizacji

## _Operacja na treści pliku wejściowego_

### Szyfr Vigenere'a

Program powinien sprawdzić, czy linia poleceń ma jedną z dwóch poniższych postaci:
```
nazwa_programu input output kod
```
```
nazwa_programu -d input output kod
```

gdzie ```input```, to nazwa pliku wejściowego, ```output``` to nazwa pliku wyjściowego a ```kod``` to słowo kluczowe szyfru. W pierwszym przypadku program powinien zaszyfrować zawartość pliku wejściowego szyfrem Vigenere'a - zgodnie z słowem kluczowym ```kod``` - i zapisać wynik do pliku wyjściowego. W drugim przypadku program powinien rozszyfrować zawartość pliku wejściowego zgodnie z kluczem ```kod``` i zapisać odkodowaną treść w pliku wyjściowym.

Opis szyfru Vigenere'a znajduje się w odnośniku [1]. Szyfr należy zaimplementować w postaci uogólnionej, obejmującej wszystkie znaki w kodzie ASCII.

### Odnośniki

[1] http://en.wikipedia.org/wiki/Vigen%C3%A8re_cipher

## Notatki

- nazwa pliku - otwieramy plik przerwanie 21h - jeśli się uda - ok, jeśli nie przerwanie wyrzuci błąd
- plik wejściowy - tylko do odczytu
- plik wyjściowy - jeśli istnieje - nadpisanie
- int 21h - ustawia flagę błędu - po każdym int 21h sprawdzamy flagę
- makra
- buforowane wejście / wyjście
  - ```getchar``` - sprawdzam czy mam znak w buforze, jeśli nie wczytuję nową partię (zwraca znak z bufora)
  - ```putchar``` - dodaje do bufora kolejne znaki, jeśli był pełny - zapisuje
- rozszerzyć na całe ASCII
- klucz - bez białych znaków

