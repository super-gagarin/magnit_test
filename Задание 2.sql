--psql (PostgreSQL) 14.2
--Создание исходной таблицы
CREATE TABLE IF NOT EXISTS routers(
    id integer primary key,
    from_airport VARCHAR(100) NOT NULL,
    to_airport VARCHAR(100) NOT NULL,
    price FLOAT NOT NULL
);

--Загрузка данных в исходную таблицу из json
WITH customer_json (doc) AS (
   VALUES ('[
    {"id":0, "from_airport":"Boston", "to_airport":"Chicago", "price":6.0 },
    {"id":1, "from_airport":"Boston", "to_airport":"Montreal", "price":5.0 },
    {"id":2, "from_airport":"Chicago", "to_airport":"San Jose", "price":2.0 },
    {"id":3, "from_airport":"Detroit", "to_airport":"Toronto", "price":4.0 },
    {"id":4, "from_airport":"New York", "to_airport":"Chicago", "price":2.0 },
    {"id":5, "from_airport":"Los Angeles", "to_airport":"Boston", "price":8.0 },
    {"id":6, "from_airport":"Los Angeles", "to_airport":"Detroit", "price":7.0 },
    {"id":7, "from_airport":"Los Angeles", "to_airport":"New York", "price":6.0 },
    {"id":8, "from_airport":"Toronto","to_airport":"Montreal","price":1.0 }
]'::json)
)
INSERT INTO routers (id, from_airport, to_airport, price)
SELECT p.*
FROM customer_json l
  CROSS JOIN lateral json_populate_recordset(null::Routers, doc) AS p
ON conflict (id) DO UPDATE 
  SET from_airport = excluded.from_airport, 
      to_airport = excluded.to_airport;
SELECT * from Routers;

--Определение всех доступных городов из Los Angeles с учётом пересадок
WITH RECURSIVE RoutersCTE (id, from_airport, to_airport, path, price, arrival_airport) as (
select 
  t1.id,
  t1.from_airport,
  t1.to_airport,
  cast (t1.from_airport || '->'|| t1.to_airport as text) as path,
  cast (t1.price as real) as price,
  t1.to_airport as arrival_airport
from Routers t1 where t1.from_airport = 'Los Angeles'
union all
select 
  t2.id,
  t2.from_airport,
  t2.to_airport,
  cast (RoutersCTE.path || '->'|| t2.to_airport as text) as path,
  cast (RoutersCTE.price + t2.price as real) as price,
  t2.to_airport arrival_airport
from Routers t2 join RoutersCTE on (t2.from_airport = RoutersCTE.to_airport))
select arrival_airport from RoutersCTE
group by arrival_airport;

--Cамый дешевый способ добраться из Los Angeles в Monreal с учётом пересадок
WITH RECURSIVE RoutersCTE (id, from_airport, to_airport, path, price, arrival_airport) as (
select 
  t1.id,
  t1.from_airport,
  t1.to_airport,
  cast (t1.from_airport || '->'|| t1.to_airport as text) as path,
  cast (t1.price as real) as price,
  t1.to_airport as arrival_airport
from Routers t1 where t1.from_airport = 'Los Angeles'
union all
select 
  t2.id,
  t2.from_airport,
  t2.to_airport,
  cast (RoutersCTE.path || '->'|| t2.to_airport as text) as path,
  cast (RoutersCTE.price + t2.price as real) as price,
  t2.to_airport arrival_airport
from Routers t2 join RoutersCTE on (t2.from_airport = RoutersCTE.to_airport))
select path, price, arrival_airport from RoutersCTE where arrival_airport = 'Montreal'
order by price asc
limit 1;
