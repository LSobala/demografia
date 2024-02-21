/* stworzenie bazy danych */
create database demografia


/* zmiana srtruktury tabeli 'dlugosc_zycia' */

if not exists 
	(
	select 
	* 
	from sys.objects 
	where object_id = OBJECT_ID('[dbo].[trwanie_zycia]')
	)
	create table trwanie_zycia (region nvarchar(100),plec nvarchar(20),rok int,wiek decimal(4,2))
go

truncate table trwanie_zycia
go

insert into trwanie_zycia (region, plec,rok,wiek)
select 
	region
	,[ch³opcy/dziewczynki]
	,rw.rok
	,rw.wart 
from [dbo].[Tabl#119_dalsze_zycie]
cross apply
(	
	values 
	('1990',[1990]),
	('2000',[2000]),
	('2010',[2010]),
	('2019',[2019]),
	('2020',[2020])
) rw (rok,wart)
go

drop table [dbo].[Tabl#119_dalsze_zycie]

/* zmiana nazwy kolumny */
sp_rename '[dbo].[malzenstwa_zawarte_rozwiazane].[Ma³¿eñstwa zawarte]','malzenstwa_zawarte','column'
sp_rename '[dbo].[malzenstwa_zawarte_rozwiazane].[WOJEWÓDZTWA ]','wojewodztwo','column'


/* dodanie kolumny rok do tabel w celu polaczenia ich z innymi tabelami + uzupe³nienie kolumny rok */
begin tran

	alter table [dbo].[powierzchnia] 
	add rok float

	alter table [dbo].[malzenstwa_zawarte_rozwiazane]
	add rok float
	go

	update [dbo].[powierzchnia]
	set rok=2020
	where rok is null

	update [dbo].[malzenstwa_zawarte_rozwiazane]
	set rok=2020
	where rok is null

	select * from [dbo].[powierzchnia]
	select * from [dbo].[malzenstwa_zawarte_rozwiazane]

commit tran

/* po³¹czenie kilku tabel w jedn¹ */
begin tran

	select 
		c.[wojewodztwo]
		,c.[rok]
		,c.[miasto/wies]
		,a.[malzenstwa_zawarte]
		,a.[smierc_meza]
		,a.[smierc_zony]
		,a.[rozwod]
		,c.[mezczyzni_mediana_wieku]
		,c.[kobiety_mediana_wieku]
		,b.[powierzchnia(km_kwadratowe)]
		,b.[mezczyzni(tys)]
		,b.[kobiety(tys)]
		,b.[os_na_km_kwadr]
	into dane_ogolne
	from [dbo].[malzenstwa_zawarte_rozwiazane] a
	full join [dbo].[powierzchnia] b on a.wojewodztwo=b.wojewodztwo 
				and a.[miasto/wies]=b.[miasto/wies]
	full join [dbo].[mediana] c on b.wojewodztwo=c.wojewodztwo 
				and b.[miasto/wies]=c.[miasto/wies]

	select * from  dane_ogolne

commit tran


/* stworzenie nowego schematu gdzie bêd¹ trafiaæ tabele, które zosta³y po³¹czone */
create schema archiwum
go
/* przeniesienie po³¹czonych wczeœniej tabel do archiwum */
alter schema archiwum transfer [dbo].[powierzchnia]
alter schema archiwum transfer [dbo].[mediana]
alter schema archiwum transfer [dbo].[malzenstwa_zawarte_rozwiazane]

/* sprawdzenie najd³u¿eszej nazwy wojwodztwa */
select 
	dl
from
	(
	select 
		rank () over (order by len([wojewodztwo]) desc) as rnk
		,len([wojewodztwo]) as dl, wojewodztwo 
	from [dbo].[dane_ogolne]
	) pdzp
where rnk=1

/* stworzenie tabeli zawieraj¹cej stolice poszczególnych województw */
create table stolice_wojewodztw (wojewodztwo nvarchar(19) ,stolica nvarchar (100))
go

insert into stolice_wojewodztw (wojewodztwo,stolica)
values
	('dolnoœl¹skie','Wroc³aw'),
	('kujawsko-pomorskie','Bydgoszcz'),
	('kujawsko-pomorskie','Toruñ'),
	('lubelskie','Lublin'),
	('lubuskie','Gorzów Wielkopolski'),
	('lubuskie', 'Zielona Góra'),
	('³ódzkie', '£ódŸ'),
	('ma³opolskie', 'Kraków'),
	('mazowieckie','Warszawa'),
	('opolskie','Opole'),
	('podkarpackie','Rzeszów'),
	('podlaskie','Bia³ystok'),
	('pomorskie','Gdañsk'),
	('œl¹skie','Katowice'),
	('œwiêtokrzyskie','Kielce'),
	('warmiñsko-mazurskie','Olsztyn'),
	('wielkopolskie','Poznañ'),
	('zachodniopomorskie','Szczecin')

/*zmiana struktury tabeli "ludnosc"*/
begin tran

	if not exists 
		(
		select 
			* 
		from sys.objects 
		where 
			object_id = OBJECT_ID('[dbo].[ludnosc_2]')
		)
	create table ludnosc_2 (rok float,[miasto/wies] nvarchar(6),plec nvarchar(1),liczba int)
go

insert into  [dbo].[ludnosc_2] (rok, [miasto/wies],plec,liczba)
select 
	rok
	,[miasto/wies]
	,pl.plec
	,pl.liczba 
from [dbo].[ludnosc]
cross apply
(
	values
	('M',mezczyzni),
	('K',kobiety)
) pl (plec,liczba)
go 

select * from ludnosc_2

commit tran

drop table dbo.ludnosc
go

sp_rename '[dbo].[ludnosc_2]','ludnosc'

/*zmiana struktury tabeli "plec_wiek"*/
begin tran

	if not exists 
		(
		select 
			* 
		from sys.objects 
		where 
			object_id = OBJECT_ID('[dbo].[plec_wiek_2]')
		)
	create table plec_wiek_2 (wiek int,[miasto/wies] nvarchar(6),plec nvarchar(1),liczba int)
go

insert into  [dbo].[plec_wiek_2] (wiek, [miasto/wies],plec,liczba)
select 
	wiek
	,[miasto/wies]
	,pl.plec
	,pl.liczba 
from [dbo].[plec_wiek]
cross apply
(
	values
	('M',mezczyzni),
	('K',kobiety)
) pl (plec,liczba)

go

select * from plec_wiek_2

commit tran

drop table dbo.plec_wiek
go

sp_rename '[dbo].[plec_wiek_2]','plec_wiek'


/*usuniêcie tych wierszy gdzie w kolumnie miasto w rzeczywistoœci znajdowa³o siê województwo*/
delete from [dbo].[miasto]
where [WOJEWÓDZTWA]=[miasto]

/* zmiana nazwy kolumn */
sp_rename '[dbo].[miasto].[WOJEWÓDZTWA]','wojewodztwo','column'

sp_rename '[dbo].[miasto].[2020 mê¿czyŸni]','2020_mezczyzni','column'


/*dodanie kolumny z liczb¹ kobiet do tabeli miasto*/
begin tran

	select 
		*
		,[2020]-[2020_mezczyzni] as [2020_kobiety]
	into [dbo].[miasto2] 
	from [dbo].[miasto]


	drop table [dbo].[miasto]

	select 
		* 
	from [dbo].[miasto2]

commit tran 

sp_rename '[dbo].[miasto2]', 'miasto'

--usuniêcie dzielnic miast
delete from [dbo].[miasto]
where left([miasto],1)=''

/* dodanie do tabeli miasto kolumn -  1) miejsce w wojewodztwie pod wzglêdem liczby mieszkañców, 2)informacja czy miasto ma ponad 50 tysiêcy mieszkañców */

begin tran

	if not exists 
		(
		select 
			* 
		from sys.objects 
		where 
			object_id = OBJECT_ID ('[dbo].[miasto2]')
		)

	select 
		*
		,rank() over (partition by [wojewodztwo] order by [2020] desc)  as ranking_wojewodztwo
		,iif 
			(
			[2020]>50000
			,'tak'
			,'nie'
			) as powyzej_50_tys
	into [dbo].[miasto2]
	from [dbo].[miasto]
	go

	select 
		* 
	from miasto2
	
commit tran

drop table [dbo].[miasto]
go
sp_rename '[dbo].[miasto2]','miasto'


/*wyodrebnienie z tabeli danych dotycz¹cych ca³ego kraju*/
select 
	wojewodztwo
	,rok,[miasto/wies]
	,mezczyzni_mediana_wieku
	,kobiety_mediana_wieku
into mediana_kraj
from [dbo].[dane_ogolne]
where [wojewodztwo]='polska'

delete from [dbo].[dane_ogolne]
where [wojewodztwo]='polska'

/*dodanie danych dotycz¹cych udzia³y kobiet i mê¿czyzn w ogólnej populacji*/

begin tran

	alter table [dbo].[dane_ogolne]
	add udzial_mezczyzn decimal (4,2)

	alter table [dbo].[dane_ogolne]
	add udzial_kobiet decimal (4,2)


	select 
	[wojewodztwo]
	,[miasto/wies]
	,[mezczyzni(tys)]/([mezczyzni(tys)]+[kobiety(tys)]) as udzial_mezczyzn 
	,[kobiety(tys)]/([mezczyzni(tys)]+[kobiety(tys)]) as udzial_kobiet
	into #tym
	from [dbo].[dane_ogolne] 

	go

	select 
	a.[wojewodztwo]
	,a.[rok] 
	,a.[miasto/wies]
	,a.[malzenstwa_zawarte]
	,a.[smierc_meza]
	,a.[smierc_zony] 
	,a.[rozwod] 
	,a.[mezczyzni_mediana_wieku]
	,a.[kobiety_mediana_wieku]
	,a.[powierzchnia(km_kwadratowe)]
	,a.[mezczyzni(tys)]
	,a.[kobiety(tys)]
	,a.[os_na_km_kwadr]
	,b.udzial_mezczyzn 
	,b.udzial_kobiet
	into [dbo].[dane_ogolne2] 
	from [dbo].[dane_ogolne] a 
	left join #tym b  on a.[wojewodztwo]=b.wojewodztwo and a.[miasto/wies]=b.[miasto/wies]

	select * from dane_ogolne2
commit tran

drop table [dbo].[dane_ogolne]
go
sp_rename '[dbo].[dane_ogolne2]','dane_ogolne'

/* dodanie kolumny zmiana pokazuj¹cej zmianê rok do roku w liczbie ludnoœci */
begin tran

	alter table [dbo].[miasto]
	add zmiana_liczbowa int default (0) with values

	alter table [dbo].[miasto]
	add zmiana_procentowa decimal(3,2) default (0) with values

commit tran
go

begin tran

	update [dbo].[miasto] 
	set zmiana_liczbowa =isnull([2020]-[2019],0)

commit tran

begin tran

	update [dbo].[miasto] 
	set zmiana_procentowa = (([2020]-[2019])/[2019])

commit tran

/* wyczyszczenie danych dotycz¹cych wieku, tak by wiek powy¿ej 99 lat pokazywa³ siê w nowej kolumnie "uwagi" */
alter table [dbo].[plec_wiek] 
add uwagi varchar(3)
go

update [dbo].[plec_wiek]
set uwagi='>99'
where [wiek] is null

/* zmiana danych w konkretnej kolumnie */
update [dbo].[trwanie_zycia]
set[plec]='M'
where [plec]='ch³opcy'
go

update [dbo].[trwanie_zycia]
set [plec]= 'K'
where [plec]='dziewczynki'

/* dodanie kolumn do tabeli */
alter table [dbo].[trwanie_zycia]
add liczba_osob_w_wieku_produkcyjnym int

alter table [dbo].[trwanie_zycia]
add liczba_emerytow int

sp_rename '[dbo].[trwanie_zycia].[region]','wojewodztwo','column'
/* dodanie danych do tabeli */
update [dbo].[trwanie_zycia]
set [liczba_osob_w_wieku_produkcyjnym] =
	(
	select
		sum(liczba) as liczba_mezczyzn_w_wieku_produkcyjnym
	from [dbo].[plec_wiek]
	where 
		[plec]='M'
		and [wiek] between 18 and 65
	)
where 
	[plec]='M' 
	and [wojewodztwo]='Polska' 
	and [rok]='2020'
go

update [dbo].[trwanie_zycia]
set [liczba_osob_w_wieku_produkcyjnym]=
	(
	select
		sum(liczba) as liczba_kobiet_w_wieku_produkcyjnym
	from [dbo].[plec_wiek]
	where 
	[plec]='K'
	and [wiek] between 18 and 60
	)
where 
	[plec]='K' 
	and [wojewodztwo]='Polska' and [rok]='2020'
go

update [dbo].[trwanie_zycia]
set [liczba_emerytow]=
	(
	select
		sum(liczba) as szacowana_liczba_mezczyzn_na_emeryturze
	from [dbo].[plec_wiek]
	where 
		[plec]='M'
		and [wiek] between 66 
		and 
			(
			select 
				round([wiek],0) 
			from [dbo].[trwanie_zycia]
			where 
				[wojewodztwo]='polska' 
				and [plec]='M' 
				and rok=
						(
						select 
							max([rok]) 
						from [dbo].[trwanie_zycia]
						)
			)
	)
where 
	[plec]='M' 
	and [wojewodztwo]='Polska' 
	and [rok]='2020'
go

update [dbo].[trwanie_zycia]
set [liczba_emerytow]=
	(
	select
		sum(liczba) as szacowana_liczba_kobiet_na_emeryturze
	from [dbo].[plec_wiek]
	where 
		[plec]='K'
		and [wiek] between 61 
		and (
			select 
				round([wiek],0) from [dbo].[trwanie_zycia]
			where 
				[wojewodztwo]='polska' 
				and [plec]='K' 
				and rok=
						(
						select 
							max([rok]) 
						from [dbo].[trwanie_zycia]
						)
			)
	)
where [plec]='K' and [wojewodztwo]='Polska' and [rok]='2020'


/*dodanie funkcji prognozujaca liczbe osob w wieku produkcyjnym oraz emerytow za X lat*/
create function prognoza_M (@lata int)
returns table
return
	select
		sum(liczba) as liczba_mezczyzn_w_wieku_produkcyjnym
	from [dbo].[plec_wiek]
	where 
		[plec]='M'
		and [wiek] between 18+@lata 
		and 65+ @lata
go

create function prognoza_K (@lata int)
returns table
return
	select
		sum(liczba) as liczba_kobiet_w_wieku_produkcyjnym
	from [dbo].[plec_wiek]
	where 
		[plec]='K'
		and [wiek] between 18-@lata 
		and 60-@lata
go

create function prognoza_M_em (@lata int)
returns table
return
	select
		sum(liczba) as szacowana_liczba_mezczyzn_na_emeryturze
	from [dbo].[plec_wiek]
	where 
		[plec]='M'
		and [wiek] between 66-@lata 
		and 
			(
			select 
				round([wiek],0)-10 
			from [dbo].[trwanie_zycia]
			where 
				[wojewodztwo]='polska' 
				and [plec]='M' 
				and rok=
						(
						select 
							max([rok]) 
						from [dbo].[trwanie_zycia]
						)
			)
go

create function prognoza_K_em (@lata int)
returns table
return
	select
		sum(liczba) as szacowana_liczba_kobiet_na_emeryturze
	from [dbo].[plec_wiek]
	where 
	[plec]='K'
	and [wiek] between 61-@lata 
	and 
		(
		select 
			round([wiek],0)-@lata 
		from [dbo].[trwanie_zycia]
		where 
			[wojewodztwo]='polska' 
			and [plec]='K' 
			and rok=
					(
					select 
						max([rok]) 
					from [dbo].[trwanie_zycia]
					)
		)
go

/* dodanie kolumn do tabeli - prognoza 10 lat do przodu */
alter table [dbo].[trwanie_zycia]
add liczba_osob_w_wieku_produkcyjnym_za_10lat int

alter table [dbo].[trwanie_zycia]
add liczba_emerytow_za_10lat int


/* dodanie danych do tabeli - prognoza 10 lat do przodu */
update [dbo].[trwanie_zycia]
set [liczba_osob_w_wieku_produkcyjnym_za_10lat] =
	(
	select 
		* 
	from [dbo].[prognoza_M] (10)
	)
where 
	[plec]='M' 
	and [wojewodztwo]='Polska' 
	and [rok]='2020'


update [dbo].[trwanie_zycia]
set [liczba_osob_w_wieku_produkcyjnym_za_10lat] =
	(
	select 
		* 
	from [dbo].[prognoza_K] (10)
	)
where 
	[plec]='K' 
	and [wojewodztwo]='Polska' 
	and [rok]='2020'

update [dbo].[trwanie_zycia]
set [liczba_emerytow_za_10lat]=
	(
	select 
		* 
	from [dbo].[prognoza_M_em] (10)
	)
where 
	[plec]='M' 
	and [wojewodztwo]='Polska' 
	and [rok]='2020'


update [dbo].[trwanie_zycia]
set [liczba_emerytow_za_10lat]=
	(
	select 
		* 
	from [dbo].[prognoza_K_em] (10)
	)
where 
	[plec]='K' 
	and [wojewodztwo]='Polska' 
	and [rok]='2020'

/*sprawdzenie salda migracji ogólem w podziale na wojewodztwa*/
select 
wojewodztwo
,saldo_m+saldo_k as saldo 
from
	(
	select 
		distinct row_number() over (partition by m.wojewodztwo order by m.wojewodztwo) as rn
		,m.[wojewodztwo]
		,m.[saldo_migracji] as saldo_m
		,k.saldo_migracji as saldo_k
	from [dbo].[migracje] m 
	inner join [dbo].[migracje] k	on m.wojewodztwo=k.wojewodztwo
	where m.plec<>k.plec 
	) pdzp
where 
	rn=1
order by 2 desc

/* dodanie kolumny z informacj¹ w których wojewodztwach udzia³ ma³¿eñstw zawartych w koœciele katolickim jest poni¿ej œredniej krajowej*/
with a as
	(
	select 
		wojewodztwo
		,religia
		,isnull(sum([miasta ]+[wies]),0) as liczba 
	from [dbo].[malzenstwa_religia]
	where 
		religia is not null
	group by religia,wojewodztwo
	),

	b as 
	(
	select 
		wojewodztwo
		,isnull(sum([miasta ]+[wies]),0) as liczba 
	from [dbo].[malzenstwa_religia]
	where 
	religia is not null
	group by wojewodztwo
	)	

select 
	* 
into pomocnicza 
from
	(
	select 
		*
	from
		(
		select 
			a.wojewodztwo
			,a.religia 
			,a.liczba
			,b.liczba as liczba_wojewodztwo
			,cast ((a.liczba/b.liczba) as decimal(5,2))*100 as procent
		from a 
		left join b on a.wojewodztwo=b.wojewodztwo
		)pdzp
	)pdzp2
	

/*stworzenie funkcji obliczaj¹cej œredni udzial procentowy wyznawców konkretnej religii*/
create function srednia (@rel nvarchar(max))
returns table
as
return
	select 
		avg(procent) as av 
	from pomocnicza
	where 
		religia=@rel
go

/* dodanie informacj¹ w których wojewodztwach udzia³ procentowy wyznawców Koœcio³a Katolickiego jest poni¿ej œredniej krajowej*/
alter table [dbo].[malzenstwa_religia]
add komentarz nvarchar(20)
go

update [dbo].[malzenstwa_religia]
set komentarz='ponizej sredniej'
where 
	wojewodztwo in
		(
		select 
			wojewodztwo
		from
			(
			select
				*
				,iif(
					procent<(
							select 
								* 
							from srednia ('Koœció³ Katolicki')
							)
					,'ponizej sredniej'
					,NULL
					) as komentarz
			from pomocnicza
			where 
				religia ='Koœció³ Katolicki'
			) pdzp
		where 
			komentarz is not null
		)
	and 
		religia ='Koœció³ Katolicki'
go

drop table pomocnicza

/* dodanie dodatkowych danych dotycz¹cych ca³ego wojewodztwa (gestosc zaludnienia, ranking powierzchnia, ranking ludnosc) do tabeli dane ogolne */
with cte as
	(
	select
		[wojewodztwo]
		,miejsce_wojewodztwa_pod_wzgledem_powierzchni
		,dense_rank() over (order by (mez_tys+kob_tys) desc) as miejsce_wojewodztwa_pod_wzgledem_ludnosci
		,(mez_tys+kob_tys)*1000/pow as os_na_km_kwadr_woj
	from
		(
		select 
			[wojewodztwo]
			,sum([malzenstwa_zawarte]) mal_zaw
			,sum([rozwod]) as rozwod
			,sum([powierzchnia(km_kwadratowe)]) as pow
			,sum([mezczyzni(tys)]) as mez_tys
			,sum([kobiety(tys)]) as kob_tys
			,dense_rank() over (order by sum([powierzchnia(km_kwadratowe)]) desc) as miejsce_wojewodztwa_pod_wzgledem_powierzchni
		from [dbo].[dane_ogolne]
		group by wojewodztwo
		)pdzp
	)

select 
	a.*
	,b.miejsce_wojewodztwa_pod_wzgledem_powierzchni
	,b.miejsce_wojewodztwa_pod_wzgledem_ludnosci
	,b.os_na_km_kwadr_woj
into dane_ogolne_2 
from [dbo].[dane_ogolne] a 
left join cte b on a.wojewodztwo=b.wojewodztwo

drop table [dbo].[dane_ogolne]
go

sp_rename '[dbo].[dane_ogolne_2]','dane_ogolne'

/* sprawdzenie które miasto ma najwiêcej wyrazów */
select 
	*
from
	(
	select 
		charindex(' ',miasto) as jedna
		,charindex(' ',miasto,charindex(' ',miasto)+1) as dwie
		,charindex
			(' ', miasto,
				(charindex
					(' ',miasto,charindex
									(' ',miasto
									)+1
					) +1
				)
			) as trzy
		,miasto
		,wojewodztwo
	from [dbo].[miasto]
	)pdzp
where trzy >0 and dwie>0

/* zmiana struktury tabeli malzenstwa_wiek */
select 
	*
into malzenstwa_wiek_2
from [dbo].[malzenstwa_wiek]
unpivot
	(
	wartosc for
	lata in
		(
		[ponizej_20], [20–24], [25–29], [30–34], [35–39], [40–44], [45–49], [50–54], [55–59], [60_lat_i_wiecej]
		)
	)unpiv
go

select 
	* 
from  [dbo].[malzenstwa_wiek_2]
go

alter schema archiwum transfer [dbo].[malzenstwa_wiek]
go

sp_rename '[dbo].[malzenstwa_wiek_2]', 'malzenstwa_wiek'


/* dodanie do tabeli malzenstwa_wiek danych dotycz¹cych ca³ego kraju bez podzia³u na miasto/wies i poszczególne lata */

select 
	rok
	,round(
			(
			sum(mediana_wiek*wartosc)/sum(wartosc)
			),1
		  ) as mediana_wieku
	,plec
	,'ca³a Polska' as [miasto/wies]
	,sum(wartosc) as wartosc
	,'ca³oœæ' as lata
into #tymczasowa2
from
(
	select 
		plec
		,[miasto/wies]
		,rok
		,sum(wartosc) as wartosc
		,avg(mediana_wieku) as mediana_wiek
	from malzenstwa_wiek
	group by 
		rok
		,plec
		,[miasto/wies]
) podz
group by plec,rok
go

sp_rename '[dbo].[malzenstwa_wiek]','malzenstwa_wiek_2'
go

select 
	*
into malzenstwa_wiek
from
	(
	select 
		* 
	from #tymczasowa2
	union
		select 
			* 
		from malzenstwa_wiek_2
	) podz
go

select 
	* 
from malzenstwa_wiek
go

alter schema archiwum transfer [dbo].[malzenstwa_wiek_2]


/* funkcja licz¹ca zmienê mediany wieku zawarcia ma³¿eñstwa */
create function roznica (@plec nvarchar(1))
returns float
as
begin

	declare @wynik float;
		with med1980 
		as
			(
			select 
				mediana_wieku as mediana_wiek
			from [dbo].[malzenstwa_wiek]
			where 
				[miasto/wies]='ca³a Polska' 
				and rok=(
						select 
							min(rok) 
						from malzenstwa_wiek
						) 
				and plec=@plec
			)
		,
		med2020
		as
			(
			select 
				mediana_wieku as mediana_wiek
			from [dbo].[malzenstwa_wiek]
			where 
				[miasto/wies]='ca³a Polska' 
				and rok=
						(
						select 
							max(rok) 
						from malzenstwa_wiek
						) 
				and plec=@plec
			)

		select 
			@wynik=a.mediana_wiek-b.mediana_wiek 
		from med2020 a
		cross join med1980 b
	return @wynik

end

/* stworzenie widoku pokazuj¹cego liczbê osób w danym wieku bez podzia³u na p³eæ i miejsce zamieszkania */
create view [dbo].[wiek]
as
	select 
		wiek
		,sum(liczba) as liczba 
	from [dbo].[plec_wiek]

	group by 
		wiek

/* dodanie do widoku informacji o tym ile procent ca³ej populacji stanowi¹ osoby o okreœlonym wieku lub m³odsze*/
ALTER view [dbo].[wiek]
as
with cte as
		(
		select 
			wiek
			,sum(liczba) as liczba 
		from [dbo].[plec_wiek]
		where 
			wiek is not null
		group by wiek
		union
		select 
			100 as wiek
			,sum(liczba) as liczba 
		from [dbo].[plec_wiek]
		where 
			wiek is null
		)
select 
	*
	,cast((sum(cast(liczba as decimal)) over (order by wiek))/cast((select sum(liczba)from cte) as decimal) as decimal(5,4))
	as procent_ludnosci_narastaj¹co
from cte
go

select * from [dbo].[wiek]

/* stworzenie widoku pokazuj¹cego wiek narastaj¹co z podzia³em na kwartyle i oznaczeniem przedzia³ów wiekowych */
create view wiek_narastajaco 
as
	with wiek_narast
	as
		(
		select 
			w2.wiek as wiek
			,w2.liczba as liczba
			,(
				select 
					sum(liczba) 
				from [dbo].[wiek] w
				where 
					w.wiek<=w2.wiek
			 ) as liczba_narastaj¹co
		from [dbo].[wiek] w2
		where 
			wiek is not null
		union
			select 
				100
				,(
					select 
						liczba 
					from dbo.wiek
					where 
						wiek is null
				 )
				,sum(liczba) as liczba
			from dbo.wiek
		)

	select 
		case 
			when kwartyl=1 
			then '0-25'
			when kwartyl=2 
			then '26-50'
			when kwartyl=3 
			then '51-75'
			else 'powy¿ej 75' 
		end as przedzia³
		,kwartyl
		,wiek
		,liczba
		,liczba_narastaj¹co
	from
		(
		select 
			ntile(4) over (order by liczba_narastaj¹co) as kwartyl
			,* 
		from wiek_narast
		) pdzp

