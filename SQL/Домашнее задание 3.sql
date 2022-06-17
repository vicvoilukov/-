-- Task 1
-- Display for each buyer his address, city and country of residence.

select concat(c.last_name, ' ', c.first_name), a.address, c2.city, country 
from customer c
left join address a on c.address_id = a.address_id 
left join city c2 on c2.city_id = a.city_id
left join country c3 on c3.country_id = c2.country_id

-- Task 2
-- Count the number of customers for each store.
-- And display only those stores that have more than 300 customers. 
-- To solve, use filtering by grouped rows with an aggregation function.

select s.store_id as "ID магазина",  count(c.customer_id) as "Количество покупателей"--, c2.city 
from store as s
left join customer c on s.store_id = c.store_id 
left join address a on s.address_id = a.address_id
group by s.store_id 
having count('Количество покупателей') > 300

--Refine the request by adding information about the city of the store, 
-- the last name and first name of the seller who works in it.

select st.store_id as "ID магазина", 
t.count as "Количество покупателей", 
t.city as "Город", 
concat(st.last_name, ' ', st.first_name) as "Имя сотрудника"
from staff st 
inner join 
	(select s.store_id, ci.city, count(c.customer_id)
	from store s
	inner join customer c on s.store_id = c.store_id 
	inner join address a on s.address_id = a.address_id
	inner join city ci on a.city_id = ci.city_id
	group by s.store_id, ci.city) as t on t.store_id = st.store_id 
where t.count > 300 

-- Task 3
-- Display the top 5 customers who have rented the most films of all time.

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя", count(r.rental_id) as "Количество фильмов"
from  customer c
inner join rental r on r.customer_id = c.customer_id 
--where r.customer_id = null -- Проверка
group by c.customer_id
order by count(r.rental_id) desc  
limit 5

-- Task 4
-- Calculate 4 analytical indicators for each customer:
-- number of rented films;
-- total cost of rental payments for all films (round to the nearest whole number);
-- minimum value of the film rental payment;
-- maximum value of the film rental payment.

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя", count(p.rental_id) as "Количество фильмов", 
round(sum(p.amount)) as "Общая стоимость платежей", min(p.amount) as "Минимальная стоимость платежа", 
max(p.amount) as "Максимальная стоимость платежа"
from  customer c
join rental r on r.customer_id = c.customer_id 
inner join payment p  on p.customer_id = c.customer_id and p.rental_id = r.rental_id 
group by c.customer_id

-- Task 5
-- Using the data from the city table, use a single query to create all possible pairs of cities 
-- so that no pairs with the same city name end up.
-- To solve it, you need to use the Cartesian product.

select c.city, c2.city
from city c 
cross join city c2
where c.city <> c2.city 

-- Task 6
-- Using the data from the rental table on the rental date of the movie (rental_date field) 
-- and the return date (return_date field), calculate for each customer the average number of days in which he returns films.

select customer_id,
round(avg(cast(r.return_date as date) - cast(r.rental_date as date)), 2) as "Среднее количество дней аренды"
from rental r 
group by customer_id 
order by customer_id asc

-- Additional part

-- Additional task 1
-- Calculate for each movie how many times it was rented, 
-- also the total cost of renting the movie for the entire time.

select f.title as "Название фильма", 
f.rating  as "Рейтинг", 
c2."name" as "Жанр",
f.release_year as "Год выпуска",
l."name" as "Язык",
count(t.count) as "Количество аренд",
sum(t.sum) as "Общая стоимость аренды"
from film f
inner join film_category fc ON fc.film_id = f.film_id
inner join category c2  on c2.category_id = fc.category_id
inner join "language" l on l.language_id = f.language_id  
left join 	
	(select i.film_id, r.rental_id, count(r.rental_id), sum(p.amount) 
	from inventory i 
	left join rental r on r.inventory_id = i.inventory_id 
	join customer c on c.customer_id = r.customer_id 
	left join payment p on p.rental_id = r.rental_id and p.customer_id = c.customer_id 
	group by i.film_id, r.rental_id, i.inventory_id) as t on t.film_id = f.film_id 
group by f.film_id, c2."name", l."name"
order by 6 asc
	
-- Additional task 2
-- Refine the query from the previous task and use it to display films that have never been rented.

select f.title as "Название фильма", 
f.rating  as "Рейтинг", 
c2."name" as "Жанр",
f.release_year as "Год выпуска",
l."name" as "Язык",
count(t.count) as "Количество аренд",
sum(t.sum) as "Общая стоимость аренды"
from film f
inner join film_category fc ON fc.film_id = f.film_id
inner join category c2  on c2.category_id = fc.category_id
inner join "language" l on l.language_id = f.language_id  
left join 	
	(select i.film_id, r.rental_id, count(r.rental_id), sum(p.amount) 
	from inventory i 
	left join rental r on r.inventory_id = i.inventory_id 
	join customer c on c.customer_id = r.customer_id 
	left join payment p on p.rental_id = r.rental_id and p.customer_id = c.customer_id 
	group by i.film_id, r.rental_id, i.inventory_id) as t on t.film_id = f.film_id 
group by f.film_id, c2."name", l."name"
having count(t.count) = 0
order by 6 asc

	
-- Additional task 3
-- Count the number of sales made by each salesperson. 
-- Add a calculated "Bonus" column. 
-- If the number of sales exceeds 7,300, then the value in the column will be "Yes", 
-- otherwise it should be "No".

select p.staff_id, count(p.rental_id) as "Количество продаж", 
	case
		when count(p.rental_id) > 7300 then 'Да'
		when count(p.rental_id) < 7300 then 'Нет'
		else 'Нет'
	end as "Премия"
from payment p  
group by staff_id
