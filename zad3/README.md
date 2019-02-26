## Zadanie 3 - zajęcia 5,6 i 7

### Cel ćwiczenia

Celem zadania realizowanego w trakcie trzech ostatnich laboratoriów jest zaznajomienie studentów z funkcjami przerwania 10h BIOS, służącego do realizacji operacji graficznych. Ponadto w ramach ćwiczenia studencin zaznajomieni zostaną z podstawowymi aspektami programowania koprocesora arytmetyki zmiennoprzecinkowej.

### Zadanie

W ramach zadania 3 każdy student zaimplementuje program realizujący prostą grafikę VGA. Oprócz operacji graficznych w przerwaniu 10h, program wykonywał będzie także pewne obliczenia zmiennoprzecinkowe. Szczegółowe omóweinie architektury i listy instrukcji koprocesora arytmetyki zmiennoprzecinkowej dostępne jest w odnośniku [1].

Wszystkie niezbędne argumenty programu powinny być wczytywane w wiersza poleceń. Program musi sprawdzić poprawność przekazancyh argumentów oraz - jeśli to konieczne - dokonać ich konwersji na odpowiedni format wewnętrzny.

Na ocenę rozwiązania składają się:
1. poprawność implementacji, w tym poprawne wykorzystanie rejestrów koprocesora arytmetyki zmiennoprzecinkowej,
2. przejrzystość implementacji, w tym należyte skomentowanie poszczególncyh partii instrukcji w programi, unikanie nadmiarowych / nieczytelnych instrukcji skoku oraz prawidłowy podział programu na procedury,
3. terminowość realizacji

### Rysowanie wypełnionego zbioru Julii

Program ma zadanie narysować fragment wypełnionego zbioru Julii. Bezpośrenio po uruchomieniu, program wczytuje z wiersza poleceń sześć liczb zmiennoprzecinkowych: ```xmin```, ```xmax```, ```ymin```, ```ymax```, ```cr``` i ```ci```. Zakładamy, że liczby wprowadzone są w formacie "klasycznym", np. ```1234.56```. Każdy inn foramt program powinien potraktować jako błąd. Po wczytaniu i konwersji liczb, program przechodzi w tryb graficzny i rozpoczyna rysowanie fragmentu zbioru Julii zawartego w kwadracie o narożnikach: lewy górny = ```(xmin, ymin)``` i prawy dolny = ```(xmax, ymax)```.

W tym celu program przechodzi w dwóch zagnieżdżonych pętlach po wszystkich pikselach na ekranie. Niech ```N```, ```M``` będą współrzędnymi ekranowymi aktualnego piksela. Program konwertuje je na współrzędne w układzie ```xmin-xmax/ymin-xmax```:
```
zr = xmin + N*(xmax-xmin)/rozdzielczość_ekranu_w_osi_x
zi = ymin + M*(ymax-ymin)/rozdzielczość_ekranu_w_osi_y
```

Następnie program wykonuje poniższe operacje arytmetyczne (pseudokod):
```
x = zr
y = zi
for(i=0;i<1000;i++)
{
    tmp = x*x - y*y + cr
    y = 2*x*y + ci
    x = tmp
    if (x*x + y*y > 4.0) break
}
if(i == 1000) wynik = 1
if(i < 1000) wynik = 0
```

Jeśli po wykonaniu powyższych operacji zachodzi warunke ```wynik == 1``` (co oznacza, że wykonane wszystkie 1000 iteracji pętli) to bieżący piksel otrzymuje kolor biały. Jeśli natomiast po wykonaniu powyższych operacji zachodzi ```wynik == 0``` (co oznacza, że wykonane mniej niż 1000 iteracji ze względu na przerwanie pętli instrukcją ```break```) to piksel otrzymuje kolor czarny.

Przykładowy wypełniony zbiór Julii otrzymamy po wykonaniu powyższych operacji dla wszystkich pikseli, przy parametrach: ```xmin=-1.5```, ```xmax=1.5```, ```ymin=-1.5```, ```ymax=1.5```, ```cr=-0.123``` i ```ci=0.745```.

### Odnoścniki

[1] http://bogdro.ciki.me/dos/a_kurs05.htm

## Notatki

- podkęcić cykle w DOSBox'sie
- ```ffree``` - skasowanie elementu z koprocesora
- tylko jedno ```finit```
- tymczasowe wyniki w pamięci - 4 bajty / 8 bajtów / 10 bajtów
- argumenty zawsze ```coś.coś```, można przyjąć, że zawsz +/-
- piksele - 10h lub wstawienie wartości (kolor) od pamięci
- po zakończeniu do trybu tekstowego (grafika, press key, do tekstowego)