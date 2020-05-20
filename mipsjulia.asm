
		.data

buff:		.space 4
offset:		.space 4
size:		.space 4
width:		.space 4
height:		.space 4
poczatek:	.space 4

msgIntro:	.asciiz "--- Zbiory Julii ---\n"
msgTemp:	.asciiz "Plik zostal wczytany: "
msgFileExc:	.asciiz "Blad pliku \n"
fileNameIn:	.asciiz "in.bmp"
fileNameOut:	.asciiz "JULIA_DONE.bmp"

real_q: .asciiz "\nLiczbe wpisz jako liczbę calkowita trojcyfrowa (zostanie ona przeskalowana).\n Przykladowe wartosci: Re=340, Im=-050; Re=370, Im=100; Re=000, Im=800  \nWpisz czesc rzeczywista liczby, na podstawie ktorej tworzony jest fraktal:  \n0."
imaginary_q: .asciiz "\nWpisz czesc urojona liczby:  \n0."

		.text
		.globl main

main:
	# wyswietlenie nagłówka:
	la $a0, msgIntro
	li $v0, 4
	syscall
	
odczytPliku:
	#************************************************************************#
	#                       Zawartosc rejestrow:
	#	 $t1 - deskryptor pliku
	#	 $s0 - rozmiar pliku
	#	 $s1 - adres zaalokowanej pamieci
	#	 $s2 - szerokość
	#	 $s3 - wysokość
	#************************************************************************#

	# otworzenie pliku o nazwie zadanej fileNameIn:
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	move $t1, $v0 		# deskryptor pliku przypisany do $t1
	
	#sprawdzenie, czy udało się otwarcie pliku
	bltz $t1, fileExc
	
	# odczytanie 2 bajtow 'BM':
	move $a0, $t1
	la $a1, buff
	li $a2, 2
	li $v0, 14
	syscall
	
	# odczytanie 4 bajtow (okreslajacych rozmiar pliku)
	move $a0, $t1
	la $a1, size
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s0, size		# zapisanie rozmiaru w $s0
	
	# alokacja pamieci o rozmiarze pliku:
	move $a0, $s0
	li $v0, 9
	syscall
	
	move $s1, $v0		# adres zaalokowanej pamieci w $s1
	sw $s1, poczatek
	
	# odczytanie 4 bajtow zarezerwowanych:
	move $a0, $t1		# przywrocenie deskrptora pliku dla $a0
	la $a1, buff
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie offsetu:
	move $a0, $t1
	la $a1, offset
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie 4 bajtow naglowka informacyjnego:
	move $a0, $t1
	la $a1, buff
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie szerokosci obrazka:
	move $a0, $t1
	la $a1, width
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s2, width			# zaladowanie szerokości do $s2
	
	# odczytanie wysokosci obrazka:
	move $a0, $t1
	la $a1, height
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s3, height			# zaladowanie wysokości do $s3
	
	# zamkniecie pliku:
	move $a0, $t1
	li $v0, 16
	syscall
	
odczytPikseli:
	# wczytuje tablice pikseli pod adres zaalokowanej pamieci w $s1
	la $a0, fileNameIn
	la $a1, 0
	la $a2, 0
	li $v0, 13
	syscall
	
	move $t1, $v0
	
	move $a0, $t1
	la $a1, ($s1)
	la $a2, ($s0)		# wczytanie tylu bajtow, ile ma plik
	li $v0, 14
	syscall
	
	lw $s0, size
	
	move $a0, $t1		# zamkniecie pliku
	li $v0, 16
	syscall
	
negative:
	#************************************************************************#
	#			 Zawartosc rejestrow:				 #
	#
	# $s0 - rozmiar
	# $s1 - adres zaalokowanej pamieci (gdzie wczytany zostal caly plik bmp)
	# $s2 - szerokosc
	# $s3 - wysokosc
	# $s5 - offset (potem rejestr pomocniczy przy obliczeniach - licznik)
	# $t5 - liczba pikseli w calym pliku (wyznacznik końca petli)
	# $s6 - część rzeczywista liczby
	# $s7 - część urojona liczby							 

	# $t1 - pozycja X
	# $t2 - pozycja Y
	# $t3 - image buffer
	# $t4 - licznik przerobionych pikseli
	
	#**************************************************************************#
	#pobranie danych, przygotowanie
	 
	li $v0, 4           
	la $a0, real_q
	# urzytkownik podaje częśc rzeczywistą
	syscall
	
	li $v0, 5
	syscall
	move $s6, $v0
	#szapisanie
	li $v0, 4           
	la $a0, imaginary_q
	# urzytkownik podaje częśc urojoną
	syscall
	
	li $v0, 5
	syscall
	move $s7, $v0 
	#zapisanie
	move $s7, $v0 

	
	#skalowanie otrzymanych liczb
	mul $s6,$s6,10
	mul $s7,$s7,10
	
	#zapisanie pozycji X i Y
	move $t1,$s2
	move $t2, $t1 
	subi $t1, $t1, 1 #korekcja pierwszego odwołanie do Y

	#przejście za offset
	lw $s5, offset
	add $s1, $s1, $s5
	
	
	li $s5,0


	mul $t5, $s2, $s3
	beq $s5, $t5, saveFile




prepare: #unused - for cleaner code

	li $t0, 0
	
	li $t1, 22000
	divu $s4, $t1, $s2 #calc step
	div $s5, $s2
	
	mfhi $t1
	mflo $t2
	addi $t1,$t1,1
	addi $t2,$t2,1
	
	mul $t5, $s4, $t1

	mul $t6, $s4, $t2
	subi $t5,$t5,11000
	subi $t6, $t6, 11000

julia:

	mul $t7, $t5, $t5
	div $t7, $t7, 10000
	#x^2
	

	mul $t8, $t6, $t6
	div $t8, $t8, 10000
	#y^2
	sub $t7, $t7, $t8
	#x^2-y^2

	mul $t8, $t5, $t6
	div $t8, $t8, 10000
	#xy
	add $t8, $t8, $t8
	#2xy
	add $t5, $t7, $s6
	#new Re
	add $t6, $t8, $s7
	#new Im
	
	#prep to check bound

	
	mul $t7, $t5, $t5
	div $t7, $t7, 10
	
	
	mul $t8, $t6, $t6
	div $t8, $t8, 10
	
	add $t7, $t7, $t8
	# |z|^2
	bgt $t7, 40000000, save_j
	#check bound
	
	addiu $t0, $t0, 1
	#add iteration
	blt $t0, 256, julia
save_j:	#kolorowanie pikseli w zaleznosci od tego, ile razy przeszla petla Julia

	#niebieski
	li $s4, 3 #kolor const-B
	mult $t0, $s4
	mflo $t4
	sb $t4, ($s1)
	addiu $s1, $s1, 1
	#zielony
	li $s4, 7 #kolor const-G
	mult $t0, $s4
	mflo $t4
	sb $t4, ($s1)
	addiu $s1, $s1, 1
	#czerwony
	li $s4, 5 #kolor const-R
	mult $t0, $s4
	mflo $t4
	sb $t4, ($s1)
	
	#przesuniecie licznika i wskaznika
	addiu $s1, $s1, 1
	addi $s5, $s5, 1
	
	#sprawdzenie, czy nie zostaly juz pokolorowane wszystkie piksele 
	mul $t5, $s2, $s3
	beq $s5, $t5, saveFile	
	j prepare
	
	
saveFile:
	# zapisujemy wynik pracy w pliku wyjsciowym,o nazwie zdefiniowanej w naglowku
	la $a0, fileNameOut
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $t0, $v0
	
	bltz $t0, fileExc
	lw $s0, size
	lw $s1, poczatek
	
	move $a0, $t0
	la $a1, ($s1)
	la $a2, ($s0)
	li $v0, 15
	syscall
	
	move $a0, $t0
	li $v0, 16
	syscall
	
	b exit

fileExc:
	la $a0, msgFileExc
	li $v0, 4
	syscall
	
exit:	
	# zamkniecie programu:
	li $v0, 10
	syscall
	
	
	
	
	
