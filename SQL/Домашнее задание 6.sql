--======== Main part ==============

/* Task №1
Write a SQL query that displays all information about movies
with the special attribute "Behind the Scenes".*/

select film_id, title, special_features 
from film
where 
cast (special_features as text) like '%Behind the Scenes%'

/*Task №2
Write 2 more movie search options with "Behind the Scenes" attribute,
using other SQL functions or statements to look up a value in an array.*/

select film_id, title, special_features 
from film
where array[special_features] @> array ['Behind the Scenes'] is true

select film_id, title, special_features 
from film
where array[special_features] && array ['Behind the Scenes'] is true

select film_id, title, special_features 
from film
where array ['Behind the Scenes'] <@ array[special_features] is true


/* Task №3
For each customer, count how many films he rented
with the special attribute "Behind the Scenes."
Prerequisite to run the job: use the query from job 1 placed in the CTE. 
CTE must be used to solve the task.*/

with t as (
	select film_id
	from film
	where array[special_features] @> array ['Behind the Scenes'] is true
	)
select customer_id,
count (rental_id)
from t
join inventory i using (film_id)
join rental r using (inventory_id)
group by customer_id 
order by customer_id 

/* Task №4
For each customer, count how many films he rented
with the special attribute "Behind the Scenes."
Prerequisite to complete the task: use the query from task 1 placed in a subquery 
that must be used to solve the task.*/
	
select customer_id,
count (rental_id)
from (
	select film_id 
	from film
	where 
	array[special_features] @> array ['Behind the Scenes'] is true
	) as t
join inventory i using (film_id)
join rental r using (inventory_id)
group by customer_id 
order by customer_id 



/* ЗАДАНИЕ №5
Create a materialized view with the query from the previous task 
and write a query to update the materialized view.*/

create materialized view m_view
as
	select customer_id,
	count (rental_id)
	from (
		select film_id 
		from film
		where 
		array[special_features] @> array ['Behind the Scenes'] is true) as t
	join inventory i using (film_id)
	join rental r using (inventory_id)
	group by customer_id 
	order by customer_id 
with no data

refresh materialized view m_view

select * from m_view;

drop materialized view m_view

/* Task №6
Use explain analyze to analyze the speed of query execution from previous tasks*/

explain analyze --72.50
select *
from film
where 
cast (special_features as text) like '%Behind the Scenes%'

explain analyze --67.50
select *
from film
where array[special_features] @> array ['Behind the Scenes'] is true

explain analyze --67.50
select *
from film
where array[special_features] && array ['Behind the Scenes'] is true

explain analyze --67.50
select *
from film
where array ['Behind the Scenes'] <@ array[special_features] is true
 
/*Which operator or function of the SQL used when doing homework, 
searching for a value in an array is faster?
Which variant of calculations works faster,
using CTE or using subquery?*/

explain analyze --167.46
with t as (
	select film_id
	from film
	where array[special_features] @> array ['Behind the Scenes'] is true
	)
select customer_id,
count (rental_id)
from t
join inventory i using (film_id)
join rental r using (inventory_id)
group by customer_id 
order by customer_id 

explain analyze --167.46
select customer_id,
count (rental_id)
from (
	select film_id 
	from film
	where 
	array[special_features] @> array ['Behind the Scenes'] is true) as t
join inventory i using (film_id)
join rental r using (inventory_id)
group by customer_id 
order by customer_id  

/*1. To work with search in an array, it is most convenient to use search through operators for working with arrays
(regardless of how to search for a combination of text in an array)
A little slower is the search for the text in the string.

2. Also, these requests is equivalent, since in general the sequence of operations and their execution has not changed.*/



--======== Additional part ==============

/*Additional task №1

explain analyze -- 1090.30
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

/*Based on the description of the request, find the bottlenecks and describe them.
Compare with your request from the main part.
Make a line-by-line description of explain analyze in Russian of the optimized query.

ANSWER
In this query, the process of processing data and finding the correct values of 'Behind the Scenes' becomes more complicated 
by displaying the array in separate rows, which increases the number of rows several times, 
and since sql searches row by row, the number of operations increases, which puts much load on CPU
In an optimized query, information processing occurs in the following order:
1. Match the given condition in the special_features array in the film table
2. The data obtained from the processing above is stored in a hash
3. from the already obtained table in the hash there are inventory_id matches from the inventory table
4. A search is also made for the inventory_id match in the resulting table with the rental table
5. The result is stored in a hash
6. Next, the received data is combined into the final table
7. Sort the final table by customers (customer_id)
8. Grouping by customers
9. And the final action is the window function with the calculation of the total number of rented movies*/

/* Additional task №2
Using a window function, display for each employee the details of that employee's very first sale.*/


explain analyze --2449.40
with t as (
select staff_id, amount, payment_date, rental_id, customer_id,
row_number () over (partition by staff_id order by payment_date asc) as "rn"
from payment) 
select t.staff_id, film_id, title, amount, payment_date, last_name, first_name 
from t
join rental using (rental_id)
join inventory using (inventory_id)
join film using (film_id)
join customer c on t.customer_id = c.customer_id 
where rn=1


/* Additional task №3
For each store, define and display the following analytical indicators in one SQL query:
1. day on which the most films were rented (day in year-month-day format)
2. number of films rented that day
3. day on which films were sold for the smallest amount (day in the format year-month-day)
4. amount of the sale on that */


explain analyze 
with t as (	
	select staff_id, dni, rentals,
	row_number () over (partition by staff_id order by rentals desc) as "rn"
		from (select staff_id, DATE_TRUNC('day', rental_date)::date as "dni", 
		sum (count(rental_id)) over (partition by staff_id, DATE_TRUNC('day', rental_date)::date) as "rentals"
		from rental
		group by staff_id, dni
		order by dni) as tt
		),
t1 as (
	select staff_id, deni, payments,
		row_number () over (partition by staff_id order by payments asc) as "rn1"
		from (select distinct staff_id, DATE_TRUNC('day', payment_date)::date as "deni", 
		(sum (amount) over (partition by staff_id, DATE_TRUNC('day', payment_date)::date)) as "payments"
		from payment p
		order by deni) as ttt)
select store_id as "ID магазина", 
dni as "День, в который арендовали больше всего фильмов", 
rentals as "Количество фильмов взятых в аренду в этот день", 
deni as "День, в который продали фильмов на наименьшую сумму", 
payments as "Сумма продаж в этот день"
from t
join t1 using (staff_id)
join staff using (staff_id)
where rn=1 and rn1=1

