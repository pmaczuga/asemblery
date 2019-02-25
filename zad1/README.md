## Zadanie 1 - zajęcia 1 i 2
## _Prezentacja funckji skrótu klucza publicznego (ang. key fingerprint) w postaci grafiki ASCII

### Cel ćwiczenia

Celem zadania realizowanego w trakcie dwóch pierwszych spotkań laboratoryjnych jest zazanjomienie studentów z podstawowymi aspektami asemblera 8086, a w szczególności: dostępnymi rejestrami mikroprocesora i ich funkcją, segmentami pamięci operacyjnej i sopsobami jej adresacji metodami konstrukcją pętli i instrukcji sterujących za pomocą skoków warunkowych, instrukcjami operatorów logicznych, przesunięć bitowych i operatorów arytmetycznych, a także funcjami przerwania 21h realizującymi wejście z klawiatury i wyjście tekstowe na ekran.

### Zadanie

W ramach pierwszego zadania studenci zaimplementują program realizujący prostą grafikę ASCII. W szczególności, program ten będzie prezentował jako ASCII-art skróty kluczy publicznych (_key fingerprint_). Studenci zaznajomieni z współczesną dystrybucję Linuxa zapewne spotkali się już z takim sposobem "wyrażania" kluczy publicznych w pakiecie OpenSSH

```
The authenticity of host '149.156.87.95' (149.156.87.95)' can't be established. RSA key fingerprint is d5:29:3e:9a:8d:90:26:5d:6b:6b:fb:8a:bb:a5:da:23.
+--[ RSA 1024]----+
|                 |
|           . .   |
|        . ° °    |   
```
