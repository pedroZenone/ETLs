---------------------------------------------------------------------------------------------------------------
---			IBOPE grps																	                   ----
---------------------------------------------------------------------------------------------------------------
-- Para discriminar BGS no hay problema porque dejas el espacio Categoria/Sector en blanco. El tema es IBOPE
-- para revisar si hubo problemas:
use [KO_SLBU_Competitive]

alter PROCEDURE TL_IBOPEgrps 
AS 
-- HAGO UN CAMBIO EN AQUARIUS PORQUE VIENE MAL LA DATA!
update tmpIBOPEgrps SET Marca = 'AQUARIUS' where (Producto = 'ANDINA,AQUARIUS' OR Producto = 'ANDINA,AQUARIUS,MANZANA')

truncate table bolsaIBOPEgrps  -- limpio la bolsa que quedo de antes

-- 1 -- Cargo la Bolsa de marcas no existentes en la tabla normalizadora BaseConversores y que tampoco estan en la lista negra
insert into bolsaIBOPEgrps(CATEGORIA,PAIS,MARCA)
select distinct a.Subsector,a.PAIS,a.MARCA 
from dbo.tmpIBOPEgrps a
left join dbo.BaseConversores m on a.Subsector = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais]
left join dbo.ListaNegra bl on bl.Marca = a.MARCA and bl.Pais = a.PAIS and a.Subsector = bl.[Categoria/Subsector/Industry]
where m.[Marca] is null and a.[Subsector] is not null and a.MARCA is not null and  bl.Marca is null and bl.Pais is null and bl.[Categoria/Subsector/Industry] is null

-- Duplicados
select distinct a.MARCA,a.PAIS,a.Subsector,a.MES,a.AÒo,count(*)
from (select distinct MARCA,PAIS,Subsector,MES,AÒo,[Canal Agrupado] from dbo.tmpIBOPEgrps) a
inner join dbo.BaseConversores m on a.Subsector = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais] and m.[Categoria/Subsector/Industry] is not null
inner join dbo.BaseConversoresMedioGRPS med on med.[Canal Agrupado] = a.[Canal Agrupado]
group by a.MARCA, a.PAIS,a.Subsector,a.MES,a.AÒo,a.[Canal Agrupado]
having count(*) > 1 
order by a.MARCA

--2 -- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BaseIBOPEgrps
where Date in (select distinct datefromparts(AÒo,MES,1) from tmpIBOPEgrps )

-- 3 -- Cargo los datos normalizados y con los factores correspondientes
insert into BaseIBOPEgrps(DATE,PAIS,CATEGORIA,SEMANA,MARCA,ANUNCIANTE,PRIORIDAD,SUBCATEGORIA,DURACION,UNIVERSE_30S,UNIVERSE,ALL_PEOPLE_30S,ALL_PEOPLE,MEDIO)
select  (datefromparts(a.AÒo,a.MES,1)) as Date,a.Pais,m.[Categoria KO],a.Semana,
m.[Marca KO],m.[Anunciante KO],m.Prioridad, m.[Sub-Categoria],  convert(FLOAT, a.[DuraciÛn (seg)]) AS Duracion,
(convert(FLOAT,(a.Universe)) * convert(FLOAT, a.[DuraciÛn (seg)]))/30 as Universe_30,
(convert(FLOAT,(a.Universe))) AS Universe,
(convert(FLOAT,(a.[All People])) * convert(FLOAT, a.[DuraciÛn (seg)]))/30 as all_people_30,
(convert(FLOAT,(a.[All People]))) as all_people, med.[Medio KO]
from dbo.tmpIBOPEgrps a
inner join dbo.BaseConversores m on a.Subsector = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais] and m.[Categoria/Subsector/Industry] is not null
inner join dbo.BaseConversoresMedioGRPS med on med.[Canal Agrupado] = a.[Canal Agrupado]

UNION ALL  -- le agrego paraguay 2016

select  (datefromparts(a.AÒo,a.MES,1)) as Date,a.Pais,m.[Categoria KO],a.Semana,
m.[Marca KO],m.[Anunciante KO],m.Prioridad, m.[Sub-Categoria],  convert(FLOAT, a.[DuraciÛn (seg)]) AS Duracion,
(convert(FLOAT,(a.Universe)) * convert(FLOAT, a.[DuraciÛn (seg)]))/30 as Universe_30,
(convert(FLOAT,(a.Universe))) AS Universe,
(convert(FLOAT,(a.[All People])) * convert(FLOAT, a.[DuraciÛn (seg)]))/30 as all_people_30,
(convert(FLOAT,(a.[All People]))) as all_people, med.[Medio KO]
from (select * from dbo.tmpIBOPEgrps where Pais = 'PARAGUAY' and AÒo = '2016') a
inner join (select distinct MARCA,[Pais],[Anunciante KO],[Marca KO],Prioridad, [Sub-Categoria],[Categoria KO]
 from dbo.BaseConversores where Pais = 'PARAGUAY' and Marca <> 'TORRENTE' ) m on a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais]
inner join dbo.BaseConversoresMedioGRPS med on med.[Canal Agrupado] = a.[Canal Agrupado]

UNION ALL -- le agrego torrente ya que antes lo habia sacado porque tenia duplicados

select  (datefromparts(a.AÒo,a.MES,1)) as Date,a.Pais,m.[Categoria KO],a.Semana,
m.[Marca KO],m.[Anunciante KO],m.Prioridad, m.[Sub-Categoria],  convert(FLOAT, a.[DuraciÛn (seg)]) AS Duracion,
(convert(FLOAT,(a.Universe)) * convert(FLOAT, a.[DuraciÛn (seg)]))/30 as Universe_30,
(convert(FLOAT,(a.Universe))) AS Universe,
(convert(FLOAT,(a.[All People])) * convert(FLOAT, a.[DuraciÛn (seg)]))/30 as all_people_30,
(convert(FLOAT,(a.[All People]))) as all_people, med.[Medio KO]
from (select * from dbo.tmpIBOPEgrps where Pais = 'PARAGUAY' and AÒo = '2016') a
inner join (select distinct MARCA,[Pais],[Anunciante KO],[Marca KO],Prioridad, [Sub-Categoria],[Categoria KO]
 from dbo.BaseConversores where Pais = 'PARAGUAY' and Marca = 'TORRENTE' and [Categoria/Subsector/Industry] is null) m
  on a.MARCA = m.[Marca] and a.PAIS = m.[Pais]
inner join dbo.BaseConversoresMedioGRPS med on med.[Canal Agrupado] = a.[Canal Agrupado]

GO

-- test
exec TL_IBOPEgrps

create table BaseIBOPEgrps(   -- output
DATE date,
PAIS varchar(max),
CATEGORIA varchar(max),
SEMANA varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
SUBCATEGORIA varchar(max),  -- m.Category
PRIORIDAD varchar(max),
DURACION float,
UNIVERSE_30S float,
UNIVERSE float,
ALL_PEOPLE_30S float,
ALL_PEOPLE float,
MEDIO varchar(max)
)

create table bolsaIBOPEgrps(
CATEGORIA	varchar(max),
MARCA	varchar(max),
PAIS   varchar(max)
)

---------------------------------------------------------------------------------------------------------------------------------
-- Borro los duplicados de IBOPE
delete from dbo.BaseConversores
where [Pais] in (select [Pais] from dbo.BaseConversores
group by [Pais],[Categoria/Subsector/Industry],[Marca] having count(*) > 1) and
[Categoria/Subsector/Industry] in(select [Categoria/Subsector/Industry] from dbo.BaseConversores
group by [Pais],[Categoria/Subsector/Industry],[Marca] having count(*) > 1) and
[Marca] in(select [Marca]  from dbo.BaseConversores
group by [Pais],[Categoria/Subsector/Industry],[Marca] having count(*) > 1) 
and [Fuente] like '%IBOPE%'

-- testing:
-- 90128
select count(*)
from dbo.IBOPEgrps a
inner join dbo.BaseConversores m on a.[Subsector] = m.[Categoria/Subsector/Industry] and a.Marca = m.[Marca] and 
a.Pais = m.[Pais] and m.[Categoria/Subsector/Industry] is not null

-- 5464
select count(*)
from dbo.IBOPEgrps a
left join dbo.BaseConversores m on a.[Subsector] = m.[Categoria/Subsector/Industry] and a.Marca = m.Marca and 
a.Pais = m.Pais
where m.Marca is null

-- 95592
select count(*) from dbo.IBOPEgrps

-- quienes son los faltantes?
select distinct a.Marca,a.AÒo,a.Mes,a.Subsector,a.Pais
from dbo.IBOPEgrps a
inner join dbo.BaseConversores m on a.[Subsector] = m.[Categoria/Subsector/Industry] and a.Marca = m.[Marca] and 
a.Pais = m.[Pais] and m.[Categoria/Subsector/Industry] is not null

---------------------------------------------------------------------------------------------------------------
---			IBOPE Inverion																                   ----
---------------------------------------------------------------------------------------------------------------

alter PROCEDURE TL_IBOPEinversion 
AS 

truncate table bolsaIBOPEinversion  -- limpio la bolsa que quedo de antes

-- arreglo un problema mal parido de la marca
update tmpIBOPEinversion SET Marca = 'AQUARIUS' where (Producto = 'ANDINA,AQUARIUS' OR Producto = 'ANDINA,AQUARIUS,MANZANA')

update tmpIBOPEinversion SET [Marca] = [Marca] + ' ' + [Anunciante] where [Marca] = 'INSTITUCIONAL' 

-- Corrijo los meses
update tmpIBOPEinversion set Mes = '1' from tmpIBOPEinversion where Mes = 'Enero'
update tmpIBOPEinversion set Mes = '2' from tmpIBOPEinversion where Mes = 'Febrero'
update tmpIBOPEinversion set Mes = '3' from tmpIBOPEinversion where Mes = 'Marzo'
update tmpIBOPEinversion set Mes = '4' from tmpIBOPEinversion where Mes = 'Abril'
update tmpIBOPEinversion set Mes = '5' from tmpIBOPEinversion where Mes = 'Mayo'
update tmpIBOPEinversion set Mes = '6' from tmpIBOPEinversion where Mes = 'Junio'
update tmpIBOPEinversion set Mes = '7' from tmpIBOPEinversion where Mes = 'Julio'
update tmpIBOPEinversion set Mes = '8' from tmpIBOPEinversion where Mes = 'Agosto'
update tmpIBOPEinversion set Mes = '9' from tmpIBOPEinversion where Mes = 'Septiembre'
update tmpIBOPEinversion set Mes = '10' from tmpIBOPEinversion where Mes = 'Octubre'
update tmpIBOPEinversion set Mes = '11' from tmpIBOPEinversion where Mes = 'Noviembre'
update tmpIBOPEinversion set Mes = '12' from tmpIBOPEinversion where Mes = 'Diciembre'

-- 1 -- Cargo la Bolsa de marcas no existentes en la tabla normalizadora BaseConversores 
insert into bolsaIBOPEinversion(CATEGORIA,PAIS,MARCA)
select distinct a.Subsector,a.PAIS,a.MARCA
from dbo.tmpIBOPEinversion a
left join dbo.BaseConversores m on a.Subsector = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais]
left join dbo.ListaNegra bl on bl.Marca = a.MARCA and bl.Pais = a.PAIS and a.Subsector = bl.[Categoria/Subsector/Industry]
where m.[Marca] is null and a.[Subsector] is not null and a.MARCA is not null and  bl.Marca is null and bl.Pais is null and bl.[Categoria/Subsector/Industry] is null


--2 -- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BaseIBOPEinversion
where Date in (select distinct datefromparts(AÒo,MES,1) from tmpIBOPEinversion )



-- Si corres primero el BGSgrps y no hubo duplicados, entonces aca tampoco los habra!

insert into BaseIBOPEinversion(DATE,PAIS,CATEGORIA,MARCA,ANUNCIANTE,PRIORIDAD,SUBCATEGORIA,MEDIO,INVERSION_LC,INVERSION_USD,CANT_AVISOS)
select  datefromparts(a.AÒo,a.MES,1) as Date,a.Pais,m.[Categoria KO],
m.[Marca KO],m.[Anunciante KO],m.Prioridad, m.[Sub-Categoria], medios.[Medio KO],(convert(FLOAT,a.InversiÛn)) as inv,
(convert(FLOAT,(a.InversiÛn)) / convert(FLOAT, usd.CAMBIO)) as inversion_usd, (isnull(convert(INT,a.[Cant# de Avisos]),0)) as avisos
from dbo.tmpIBOPEinversion a
inner join dbo.BaseConversores m on a.Subsector = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais] and m.[Categoria/Subsector/Industry] is not null
inner join dbo.BaseConversoresUSD usd on a.AÒo = usd.ANO and a.Pais = usd.PAIS
inner join dbo.BaseConversoresMedioInversion medios on medios.[Clase de VehÌculo] = a.[Clase de VehÌculo]
GO

-- test
EXEC TL_IBOPEinversion

create table BaseIBOPEinversion(  -- output
DATE date,
PAIS varchar(max),
CATEGORIA varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
SUBCATEGORIA varchar(max),  -- m.Category
PRIORIDAD varchar(max),
MEDIO varchar(max),
INVERSION_LC FLOAT,
INVERSION_USD FLOAT,
CANT_AVISOS INT
)

create table bolsaIBOPEinversion(
CATEGORIA	varchar(max),
MARCA	varchar(max),
PAIS   varchar(max)
)

---------------------------------------------------------------------------------------------------------------
--  Nielsen																								   ----
---------------------------------------------------------------------------------------------------------------


alter PROCEDURE TL_Nielsen 
AS 
-- 1 -- Cargo la Bolsa de marcas no existentes en la tabla normalizadora BaseConversores 
truncate table bolsaNielsen  -- limpio la bolsa que quedo de antes

insert into BaseIBOPEinversion(CATEGORIA,PAIS,MARCA)
select distinct a.CATEGORIA,a.PAIS,a.MARCA 
from dbo.tmpNielsen a
left join dbo.BaseConversores m on a.CATEGORIA = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.[Pais]
left join  dbo.ListaNegra bl on bl.Marca = a.MARCA and bl.Pais = a.PAIS and a.CATEGORIA = bl.[Categoria/Subsector/Industry]
where m.[Marca] is null and a.MARCA is not null and  bl.Marca is null and bl.PAIS is null and bl.[Categoria/Subsector/Industry] is null

-- duplicados
select distinct a.MARCA,a.PAIS,a.CATEGORIA,a.ANO, a.MES,count(*)
from dbo.tmpNielsen a
inner join dbo.TablaTotales b on a.PAIS = b.PAIS and a.CATEGORIA = b.CATEGORIA and a.ANO = b.ANO and
a.MES = b.MES
inner join dbo.BaseConversores m on a.CATEGORIA = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.Pais and m.[Categoria/Subsector/Industry] is not null
group by a.MARCA, a.PAIS,a.CATEGORIA,a.MES,a.ANO 
having count(*) > 1 
order by a.MES,a.ANO,a.PAIS


--2 -- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BaseNielsen
where Date in (select distinct datefromparts(ANO,MES,1) from tmpNielsen )

-- 3 -- Cargo los datos normalizados y con los factores correspondientes
insert into BaseNielsen(PAIS,CATEGORIA,DATE,VENTAS_LC,VENTAS_UNIT,MARCA,ANUNCIANTE,PRIORIDAD,SUBCATEGORIA,VENTAS_USD)
select a.PAIS,m.[Categoria KO], datefromparts(a.ANO,a.MES,1) as Date, 
(convert(FLOAT,(a.VENTAS_PESOS)) * convert(FLOAT, b.VENTAS_PESOS))/100 as VENTAS_PESOS,
-- (convert(INT,convert(FLOAT,(a.VENTAS_UNIT))) * convert(INT,convert(FLOAT, b.VENTAS_UNIT)))/100 as VENTAS_UNIT,m.[Marca KO],
(convert(INT,(convert(FLOAT,(a.VENTAS_UNIT)) * convert(FLOAT, b.VENTAS_UNIT))/100)) as VENTAS_UNIT,m.[Marca KO],
m.[Anunciante KO],m.Prioridad,m.[Sub-Categoria],(convert(FLOAT,(a.VENTAS_PESOS)) * convert(FLOAT, b.VENTAS_PESOS) / convert(FLOAT, usd.CAMBIO))/100 as VENTAS_PESOS_USD
from dbo.tmpNielsen a
inner join dbo.TablaTotales b on a.PAIS = b.PAIS and a.CATEGORIA = b.CATEGORIA and a.ANO = b.ANO and
a.MES = b.MES
inner join dbo.BaseConversores m on a.CATEGORIA = m.[Categoria/Subsector/Industry] and a.MARCA = m.[Marca] and 
a.PAIS = m.Pais and m.[Categoria/Subsector/Industry] is not null
inner join dbo.BaseConversoresUSD usd on a.ANO = usd.ANO and a.PAIS = usd.PAIS
GO

-- test
exec TL_Nielsen

create table BaseNielsen(  -- output Nielsen
DATE date,
PAIS varchar(max),
CATEGORIA varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
SUBCATEGORIA varchar(max),  -- m.Category
PRIORIDAD varchar(max),
VENTAS_UNIT INT,
VENTAS_USD float,
VENTAS_LC float
)

create table BaseNielsenTest(  -- output Nielsen
DATE date,
PAIS varchar(max),
CATEGORIA varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
SUBCATEGORIA varchar(max),  -- m.Category
PRIORIDAD varchar(max),
VENTAS_UNIT INT,
VENTAS_USD float,
VENTAS_LC float
)

create table bolsaNielsen(
CATEGORIA	varchar(max),
MARCA	varchar(max),
PAIS   varchar(max)
)

--create table TempNielsen(  -- Input Nielsen
--CATEGORIA	varchar(max),
--MARCA	varchar(max),
--MES integer,
--PAIS varchar(max),
--VENTAS_UNIT INT,
--ANO INT,
--VENTAS_PESOS float,
--ANUNCIANTE_NIELSEN varchar(max)
--)

---------------------------------------------------------------------------------------------------------------
---			BGS  BrandLove        																                   ----
---------------------------------------------------------------------------------------------------------------

-- select * from BaseConversores where MARCA = 'Villa Santa'
-- select top(10) * from tmpBGSbrandLove

alter PROCEDURE TL_BGSbrandLove
AS 

-- transformo a uppercase
update tmpBGSbrandLove set PAIS = upper(PAIS)
update tmpBGSbrandLove set PAIS = 'PERU' where PAIS = 'PER√∫'
update tmpBGSbrandLove set PAIS = 'PERU' where PAIS = 'PER⁄'

-- duplicados. No se tiene en cuenta los subcategoria ya que puede ser que una misma marca pueda tener varias sub-categorias!!
select distinct a.MARCA,a.PAIS,a.ANO, a.MES,a.PYRAMID ,count(*)
from dbo.tmpBGSbrandLove a, (select distinct MARCA,PAIS,[Marca KO],[Anunciante KO],Prioridad
 from dbo.BaseConversores) m
where a.MARCA = m.[MARCA] and a.PAIS = m.Pais
group by a.MARCA, a.PAIS,a.MES,a.ANO,a.PYRAMID 
having count(*) > 1 
order by a.MARCA,a.MES,a.ANO,a.PAIS

truncate table bolsaBGSbrandLove

insert into bolsaBGSbrandLove
select distinct a.PAIS,a.MARCA
from dbo.tmpBGSbrandLove a
left join dbo.BaseConversores m on a.MARCA = m.[Marca] and a.PAIS = m.[Pais]
left join dbo.ListaNegra bl on bl.Marca = a.MARCA and bl.Pais = a.PAIS
where m.[Marca] is null and  bl.Marca is null and bl.Pais is null

-- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BGSbrandLove
where Date in (select distinct datefromparts(ANO,MES,1) from tmpBGSbrandLove )



insert into BGSbrandLove(PAIS,DATE,MARCA,ANUNCIANTE,PRIORIDAD,PYRAMID,METRICA)
select a.PAIS, (datefromparts(a.ANO,a.MES,1)) as Date,m.[Marca KO],m.[Anunciante KO],m.Prioridad,
a.PYRAMID,a.METRIC
from dbo.tmpBGSbrandLove a, (select distinct MARCA,PAIS,[Marca KO],[Anunciante KO],Prioridad
 from dbo.BaseConversores) m
where a.MARCA = m.[MARCA] and a.PAIS = m.Pais
GO

-- test
exec TL_BGSbrandLove 

create table BGSbrandLove(
DATE varchar(max),
PAIS varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
PRIORIDAD varchar(max),
PYRAMID varchar(max),
METRICA FLOAT
)

create table bolsaBGSbrandLove(
PAIS varchar(max),
MARCA varchar(max)
)

---------------------------------------------------------------------------------------------------------------
---			BGS  Equity  																                   ----
---------------------------------------------------------------------------------------------------------------

-- select * from BaseConversores where MARCA = 'Villa Santa'
-- select top(10) * from tmpBGSbrandLove

alter PROCEDURE TL_BGSequity
AS 

-- transformo a uppercase
update tmpBGSequity set PAIS = upper(PAIS)
update tmpBGSequity set PAIS = 'PERU' where PAIS = 'PER√∫'
update tmpBGSequity set PAIS = 'PERU' where PAIS = 'PER⁄'

-- duplicados. No se tiene en cuenta los subcategoria ya que puede ser que una misma marca pueda tener varias sub-categorias!!
select distinct a.MARCA,a.PAIS,a.ANO, a.MES,a.EQUITY ,count(*)
from dbo.tmpBGSequity a, (select distinct MARCA,PAIS,[Marca KO],[Anunciante KO],Prioridad
 from dbo.BaseConversores) m
where a.MARCA = m.[MARCA] and a.PAIS = m.Pais
group by a.MARCA, a.PAIS,a.MES,a.ANO,a.EQUITY 
having count(*) > 1 
order by a.MARCA,a.MES,a.ANO,a.PAIS

truncate table bolsaBGSequity

insert into bolsaBGSequity
select distinct a.PAIS,a.MARCA
from dbo.tmpBGSequity a
left join dbo.BaseConversores m on a.MARCA = m.[Marca] and a.PAIS = m.[Pais]
left join dbo.ListaNegra bl on bl.Marca = a.MARCA and bl.Pais = a.PAIS
where m.[Marca] is null and bl.Marca is null and bl.Pais is null

-- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BGSequity
where Date in (select distinct datefromparts(ANO,MES,1) from tmpBGSequity )

insert into BGSequity(PAIS,DATE,MARCA,ANUNCIANTE,PRIORIDAD,EQUITY,METRICA)
select a.PAIS, (datefromparts(a.ANO,a.MES,1)) as Date,m.[Marca KO],m.[Anunciante KO],m.Prioridad,
a.EQUITY,a.METRIC
from dbo.tmpBGSequity a, (select distinct MARCA,PAIS,[Marca KO],[Anunciante KO],Prioridad
 from dbo.BaseConversores) m
where a.MARCA = m.[MARCA] and a.PAIS = m.Pais
GO


-- test
exec TL_BGSequity 

create table BGSequity(
DATE varchar(max),
PAIS varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
PRIORIDAD varchar(max),
EQUITY varchar(max),
METRICA FLOAT
)

create table bolsaBGSequity(
PAIS varchar(max),
MARCA varchar(max)
)

---------------------------------------------------------------------------------------------------------------
---			BGS  Frequency 																                   ----
---------------------------------------------------------------------------------------------------------------

-- select * from BaseConversores where MARCA = 'Villa Santa'
-- select top(10) * from tmpBGSbrandLove

alter PROCEDURE TL_BGSfrequency
AS 

-- transformo a uppercase
update tmpBGSfrequency set PAIS = upper(PAIS)
update tmpBGSfrequency set PAIS = 'PERU' where PAIS = 'PER√∫'
update tmpBGSfrequency set PAIS = 'PERU' where PAIS = 'PER⁄'

-- duplicados. No se tiene en cuenta los subcategoria ya que puede ser que una misma marca pueda tener varias sub-categorias!!
select distinct a.MARCA,a.PAIS,a.ANO, a.MES,a.FREQUENCY ,count(*)
from dbo.tmpBGSfrequency a, (select distinct MARCA,PAIS,[Marca KO],[Anunciante KO],Prioridad
 from dbo.BaseConversores) m
where a.MARCA = m.[MARCA] and a.PAIS = m.Pais
group by a.MARCA, a.PAIS,a.MES,a.ANO,a.FREQUENCY 
having count(*) > 1 
order by a.MARCA,a.MES,a.ANO,a.PAIS

truncate table bolsaBGSfrequency

insert into bolsaBGSfrequency
select distinct a.PAIS,a.MARCA
from dbo.tmpBGSfrequency a
left join dbo.BaseConversores m on a.MARCA = m.[Marca] and a.PAIS = m.[Pais]
left join dbo.ListaNegra bl on bl.Marca = a.MARCA and bl.Pais = a.PAIS
where m.[Marca] is null and bl.Marca is null and bl.Pais is null

-- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BGSfrequency
where Date in (select distinct datefromparts(ANO,MES,1) from tmpBGSfrequency )

insert into BGSfrequency(PAIS,DATE,MARCA,ANUNCIANTE,PRIORIDAD,FREQUENCY,METRICA)
select a.PAIS, (datefromparts(a.ANO,a.MES,1)) as Date,m.[Marca KO],m.[Anunciante KO],m.Prioridad,
a.FREQUENCY,a.METRIC
from dbo.tmpBGSfrequency a, (select distinct MARCA,PAIS,[Marca KO],[Anunciante KO],Prioridad
 from dbo.BaseConversores) m
where a.MARCA = m.[MARCA] and a.PAIS = m.Pais
GO

-- test
exec TL_BGSfrequency

create table BGSfrequency(
DATE varchar(max),
PAIS varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
PRIORIDAD varchar(max),
FREQUENCY varchar(max),
METRICA FLOAT
)

create table bolsaBGSfrequency(
PAIS varchar(max),
MARCA varchar(max)
)


---------------------------------------------------------------------------------------------------------------
--  Admetricks																							   ----
---------------------------------------------------------------------------------------------------------------


alter PROCEDURE TL_Admetricks 
AS 

update tmpAdmetricks set Country = upper(Country)

-- 1 -- Cargo la Bolsa de marcas no existentes en la tabla normalizadora BaseConversores 
truncate table bolsaAdmetricks  -- limpio la bolsa que quedo de antes

insert into bolsaAdmetricks(CATEGORIA,PAIS,MARCA)
select  distinct a.Industry,a.Country,a.Brand 
from dbo.tmpAdmetricks a
left join dbo.BaseConversores m on a.Industry = m.[Categoria/Subsector/Industry] and a.Brand = m.[Marca] and 
a.Country = m.Pais and m.[Categoria/Subsector/Industry] is not null
left join  dbo.ListaNegra bl on bl.Marca = a.Brand and bl.Pais = a.Country and a.Industry = bl.[Categoria/Subsector/Industry]
where m.[Marca] is null and  bl.Marca is null and bl.PAIS is null and bl.[Categoria/Subsector/Industry] is null

--2 -- Borro los registros cargados con la misma fecha que quiero cargar ahora
delete from BaseAdmetricks
where Date in (select distinct CONVERT (datetime, [Date]) from tmpAdmetricks )

-- 3 -- Cargo los datos normalizados y con los factores correspondientes
insert into BaseAdmetricks(PAIS,CATEGORIA,DATE,MARCA,ANUNCIANTE,PRIORIDAD,SUBCATEGORIA,CAMPANA,PAGINA_CAMPANA ,WEBSITE,SECCION_WEBSITE,TIPO_AD,
AD_SIZE,DEVICE,HOSTED_BY,IMPACTO,IMPRESIONES,SOLD_BY,WEB_REPORT,VALUATION_USD)
select a.Country,m.[Categoria KO], CONVERT (datetime, a.[Date]) as Date, m.[Marca KO],m.[Anunciante KO], m.Prioridad,m.[Sub-Categoria], a.[Campaign Name],
a.[Campaign Landing Page],a.Website,a.[Website Section],a.[Ad Type],a.[Ad Size],a.Device,a.[Hosted by],
CONVERT(INT,a.Impact),CONVERT(INT,a.Impressions),a.[Sold by],a.[Web report], CONVERT(FLOAT,a.[Valuation (Dollars)])
from dbo.tmpAdmetricks a
inner join dbo.BaseConversores m on a.Industry = m.[Categoria/Subsector/Industry] and a.Brand = m.[Marca] and 
a.Country = m.Pais and m.[Categoria/Subsector/Industry] is not null

-- Le agrego una categoria ams a tipo de ad siempre y cuando aparzca la pagina de facebook
update BaseAdmetricks SET TIPO_AD = 'social' where (WEBSITE like '%facebook%' and TIPO_AD = 'display' )

IF
	(SELECT t.a + r.a - x.a from (select count(*) as a
	from dbo.tmpAdmetricks a
	left join dbo.BaseConversores m on a.Industry = m.[Categoria/Subsector/Industry] and a.Brand = m.[Marca] and 
	a.Country = m.Pais and m.[Categoria/Subsector/Industry] is not null
	where m.[Marca] is null ) t, (select count(*) as a
	from dbo.tmpAdmetricks a
	inner join dbo.BaseConversores m on a.Industry = m.[Categoria/Subsector/Industry] and a.Brand = m.[Marca] and 
	a.Country = m.Pais and m.[Categoria/Subsector/Industry] is not null) r, (select count(*) as a from tmpAdmetricks) x) = 0
BEGIN
	print 'No hay duplicados'
END
else
BEGIN
	print 'Hay duplicados'
END
GO

-- test
exec TL_Admetricks

create table BaseAdmetricks(  -- output Nielsen
DATE date,
PAIS varchar(max),
CATEGORIA varchar(max),
MARCA varchar(max),
ANUNCIANTE varchar(max),
SUBCATEGORIA varchar(max),  -- m.Category
PRIORIDAD varchar(max),
CAMPANA varchar(max),
PAGINA_CAMPANA varchar(max),
WEBSITE varchar(max),
SECCION_WEBSITE varchar(max),
TIPO_AD varchar(max),
AD_SIZE varchar(max),
DEVICE varchar(max),
HOSTED_BY varchar(max),
IMPACTO INT,
IMPRESIONES INT,
SOLD_BY varchar(max),
WEB_REPORT varchar(max),
VALUATION_USD FLOAT
)

create table bolsaAdmetricks(
CATEGORIA	varchar(max),
MARCA	varchar(max),
PAIS   varchar(max)
)

---------------------------------------------------------------------------------------------------------------
--  IBOPE + Nielsen																						   ----
---------------------------------------------------------------------------------------------------------------
-- Pongo las 3 tablas en una sola. Para pibotear uso date,marca,pais,categoria y anunciante. Uso coalelsce porque cuando joineo y no existe esa entrada me lo completa con null, con coalelsce tsolo se queda con una sola columna!
alter PROCEDURE TL_NielsenIBOPE
as 
truncate table BaseNielsenIBOPE

insert into BaseNielsenIBOPE(DATE,MARCA,PRIORIDAD,PAIS,CATEGORIA,ANUNCIANTE,UNIVERSE_30S,ALL_PEOPLE_30S,INVERSION_LC_IBOPE,INVERSION_USD_IBOPE,VENTAS_UNIT,VENTAS_USD,VENTAS_LC)
select  * from
(select COALESCE(iboG.DATE, n.DATE,iboI.DATE) as DATE, COALESCE(iboG.MARCA , n.MARCA, iboI.MARCA) as MARCA,
COALESCE(iboG.PRIORIDAD, n.PRIORIDAD,iboI.PRIORIDAD) as PRIORIDAD,COALESCE(iboG.PAIS, n.PAIS,iboI.PAIS) as PAIS,
COALESCE(iboG.CATEGORIA ,n.CATEGORIA,iboI.CATEGORIA) as CATEGORIA, 
COALESCE(iboG.ANUNCIANTE ,n.ANUNCIANTE,iboI.ANUNCIANTE) as ANUNCIANTE,iboG.UNIVERSE_30S, 
iboG.ALL_PEOPLE_30S,iboI.INVERSION_LC as INVERSION_LC_IBOPE ,iboI.INVERSION_USD as INVERSION_USD_IBOPE, n.VENTAS_UNIT, n.VENTAS_USD,
n.VENTAS_LC
from (select DATE,MARCA,PRIORIDAD,ANUNCIANTE,PAIS,CATEGORIA, SUM(VENTAS_USD) as VENTAS_USD, SUM(VENTAS_LC) as VENTAS_LC,SUM(VENTAS_UNIT) as VENTAS_UNIT from BaseNielsen group by DATE,MARCA,ANUNCIANTE,PAIS,CATEGORIA,PRIORIDAD) n
full JOIN (select DATE,MARCA,ANUNCIANTE,PAIS,CATEGORIA,PRIORIDAD,SUM(ALL_PEOPLE_30S) as ALL_PEOPLE_30S, SUM(UNIVERSE_30S) as UNIVERSE_30S from BaseIBOPEgrps group by DATE,MARCA,ANUNCIANTE,PAIS,CATEGORIA,PRIORIDAD)iboG
on iboG.DATE = n.DATE and iboG.MARCA = n.MARCA and iboG.PAIS = n.PAIS and iboG.CATEGORIA = n.CATEGORIA and iboG.ANUNCIANTE = n.ANUNCIANTE
full JOIN (select DATE,MARCA,PRIORIDAD,ANUNCIANTE,PAIS,CATEGORIA,SUM(INVERSION_LC) as INVERSION_LC, SUM(INVERSION_USD) as INVERSION_USD from BaseIBOPEinversion group by DATE,MARCA,ANUNCIANTE,PAIS,CATEGORIA,PRIORIDAD) iboI 
on iboI.DATE = n.DATE and iboI.MARCA = n.MARCA and iboI.PAIS = n.PAIS and 
iboI.CATEGORIA = n.CATEGORIA and iboI.ANUNCIANTE = n.ANUNCIANTE) t 

go


exec TL_NielsenIBOPE

CREATE table BaseNielsenIBOPE (
DATE date,
MARCA varchar(max),
PRIORIDAD varchar(max),
PAIS varchar(max),
CATEGORIA varchar(max),
ANUNCIANTE varchar(max),
UNIVERSE_30S float,
ALL_PEOPLE_30S float,
INVERSION_LC_IBOPE float,
INVERSION_USD_IBOPE float,
VENTAS_UNIT INT,
VENTAS_USD float,
VENTAS_LC float
)




-- update BaseConversores set [Anunciante KO]  = 'TCCC' where Marca = 'Freskyta' and Pais = 'Uruguay' and [Anunciante KO] is null
-- update BaseConversores set [Anunciante KO]  = 'WATTS ALIMENTOS S.A.' where Marca = 'watts' and Pais = 'CHILE' and [Anunciante KO] = 'ECUSA'
-- update BaseConversores set [Marca KO]  = 'ESENCIAL' where [Marca KO] = 'ESSENCIAL'
-- UPDATE  BaseConversores SET [Anunciante KO] =  'TCCC' where MARCA = 'Kola Inglesa' and [Anunciante KO] is null

--update ListaNegra set Pais = upper(Pais)
--update ListaNegra set Pais = 'PERU' where Pais = 'PER⁄'

-- update BaseConversores set [MARCA]  = 'M¡S PERA' where Marca = 'M¡ÅS PERA'
-- update BaseConversores set [MARCA]  = 'M¡S MANZANA' where Marca = 'M¡ÅS MANZANA'
-- update BaseConversores set [MARCA]  = 'M¡S UVA' where Marca = 'M¡ÅS UVA'
-- update BaseConversores set [MARCA]  = 'M¡S WOMAN F.TROPICALES' where Marca = 'M¡ÅS WOMAN F.TROPICALES'
-- insert into BaseConversores values ('BOLIVIA',	'Monster',	NULL,	'ENERGIZANTES',	'MONSTER',	'MONSTER ENERGY',	'Non-core',	'STILLS')





truncate table BaseConvers
drop table BaseConversores
truncate table tmpIBOPEinversion
truncate table ListaNegra
drop table tmpNielsen

select distinct * from BaseConversores where [Sub-Categoria] is null and [Sub-Categoria] = '#N/A'
select distinct marca from BaseConversores where marca like '%INSTITUCIONAL%' order by marca

SELECT * from BaseNielsen

SELECT * from BaseNielsen WHERE categoria is null
SELECT * from BaseNielsen WHERE anunciante is null
SELECT * from BaseNielsen WHERE MARCA is null
SELECT * from BaseNielsen WHERE prioridad is null
SELECT * from BaseNielsen WHERE subcategoria is null
SELECT * from BaseNielsen WHERE ventas_unit is null
SELECT * from BaseNielsen WHERE ventas_usd is null
SELECT * from BaseNielsen WHERE ventas_lc is null

SELECT count(*) from BaseAdmetricks WHERE campana is null   -- tiene nulos
SELECT * from BaseAdmetricks WHERE pagina_campana is null
SELECT * from BaseAdmetricks WHERE website is null
SELECT * from BaseAdmetricks WHERE seccion_website is null   -- tiene nulls
SELECT * from BaseAdmetricks WHERE tipo_ad is null
SELECT * from BaseAdmetricks WHERE ad_size is null
SELECT * from BaseAdmetricks WHERE device is null
SELECT * from BaseAdmetricks WHERE impacto is null
SELECT * from BaseAdmetricks WHERE impresiones is null
SELECT * from BaseAdmetricks WHERE sold_by is null
SELECT * from BaseAdmetricks WHERE web_report is null
SELECT * from BaseAdmetricks WHERE valuation_usd is null

select * from BaseIBOPEgrps