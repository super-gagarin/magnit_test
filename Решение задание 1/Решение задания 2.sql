--psql (PostgreSQL) 14.2
--Предварительно в БД созданы и загружены из csv файлов таблицы "Продажи 2" и "Справочник товаров 2"
--На основе таблиц "Продажи 2" и "Справочник товаров 2" создаем таблицу abc_analysis
--drop table IF EXISTS abc_analysis;
CREATE TABLE IF NOT EXISTS abc_analysis (
  year integer,
  store_format varchar(100),
  category varchar(100),
  product varchar(100),
  sum_qnty real,
  revenue real
 );

--Загружаем в таблицу abc_analysis данные из таблиц "Продажи 2" и "Справочник товаров 2"
insert into abc_analysis (
  year,
  store_format,
  category,
  product,
  sum_qnty,
  revenue
)
select 
  SUBSTRING(п."MONTH", 1, 4)::integer as "year",
  п.store_format,
  т.category,
  п.product,
  sum(п.SALES_QNTY) as sum_qnty,
  sum(cast (т.price * п.SALES_QNTY as real)) as revenue
from "Продажи 2" п
JOIN "Справочник товаров 2" т ON п.product = т.product
group by year, п.store_format, т.category, п.product
order by year, п.store_format, т.category, п.product

--Проводим ABC анализ для всех позиций в разрезе Год (YEAR), STORE_FORMAT, CATEGORY, 
--используя показатель оборот в рублях, оборот в штуках, поделив на 3 категории:
--85 % - A
--10 % - B
--5 % - C
select t.year,
       t.store_format,
       t.category,
       t.product,
       case
          when t.sum_qnty2/t.sum_qnty < 0.85 then 'A'
          when t.sum_qnty2/t.sum_qnty between 0.85 and 0.95 then 'B'
          else 'C'
       end as ABC_QNTY,
       case
          when t.sum_prod/t.revenue < 0.85 then 'A'
          when t.sum_prod/t.revenue between 0.85 and 0.95 then 'B'
          else 'C'
       end as ABC_RUB
from
     (
        SELECT year,
               store_format,
               category,
               product,
               revenue/sum(revenue) over() as persent,
               sum_qnty/sum(sum_qnty) over() as persent2,
               sum(revenue) over(order by revenue DESC, category, product) as sum_prod,
               sum(sum_qnty) over(order by sum_qnty DESC, category, product) as sum_qnty2,
               sum(revenue) over() as revenue,
               sum(sum_qnty) over() as sum_qnty
        FROM  abc_analysis
        
     ) as t
order by year, store_format, category, product
