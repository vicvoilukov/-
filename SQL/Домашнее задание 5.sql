SET search_path TO public;

--======== Main part ==============

/*Task №1
Make a request to payment table and add new calculated columns use the window functions according to the conditions:
Number all payments from 1 to N by date*/

select 
row_number() over (partition by DATE_TRUNC('day', payment_date) order by payment_date) as pay_number,
amount, payment_date
from payment p 

-- Number payments for each customer, sorting should be by date

select 
row_number() over (partition by customer_id order by payment_date) as pay_number,
c.first_name, c.last_name, amount, payment_date
from payment p 
JOIN customer c USING (customer_id)

/*Calculate the cumulative sum of all payments for each buyer, 
sorting should be first by payment date, and then by payment amount from smallest to largest*/

select customer_id, payment_date,
	SUM(amount) OVER (PARTITION BY customer_id order by payment_date, amount asc) as payment_sum
from payment p 
order by customer_id, DATE_TRUNC('day', payment_date)

/*Number the payments for each customer by payment value 
from largest to smallest so that payments with the same value have the same number value.*/

select customer_id, payment_date, amount,
dense_rank () over (partition by customer_id order by amount desc)
from payment p 

-- Combine everything in one query.

select 
c.first_name as "Имя", c.last_name as "Фамилия", 
row_number() over (partition by DATE_TRUNC('day', payment_date) order by payment_date) as "Номер платежа за день",
dense_rank () over (partition by customer_id order by amount desc) as "Номер платежа покупателя",
amount as "Сумма платежа" ,
SUM(amount) OVER (PARTITION BY customer_id order by payment_date, amount asc) as "Сумма платежей за день",
payment_date as "Дата платежа"
from payment p 
JOIN customer c USING (customer_id)
order by DATE_TRUNC('day', payment_date), "Сумма платежей за день" asc 

/*Task №2
Use a window function to display for each customer the cost of payment 
and the cost of payment from the previous row, with a default value of 0.0, sorted by date.*/

SELECT customer_id, payment_date, 
	LAG(amount, 1, 0.) OVER (partition by customer_id order by payment_date) as "Предыдущий платеж",  
	amount as "Текущий платеж" 
from payment p

/*Task №3
Using a window function, determine how much each next customer payment is more or less than the current one.*/

SELECT customer_id, payment_date, 
	LAG(amount, 1, 0.) OVER (partition by customer_id order by payment_date) as "Предыдущий платеж",  
	amount as "Текущий платеж",
	lead (amount, 1) OVER (partition by customer_id order by payment_date) - amount as "Разница от следующего платежа",
	lead (amount, 1) OVER (partition by customer_id order by payment_date) as "Следующий платеж"
from payment p

/*Task №4
Use a window function for each customer to display their last payment.*/

with t as (
select 
row_number () over (partition by customer_id order by payment_date desc) as "Номер платежа",
*
from payment)
select *
from t
where "Номер платежа" = 1

select *,
last_value (payment_date) over (partition by customer_id order by payment_date)
from payment p



--======== Additional part ==============

/*Additional task №1
Using a window function, display for each employee the sum of sales for August 2005, 
with a cumulative total for each employee and for each sale date (excluding time), 
sorted by date.*/

with t as (
select *
from payment p
where date_part('month', payment_date) = 8 
and date_part('year', payment_date) = 2005)
select staff_id, payment_date::date, 
sum(sum (amount)) over (partition by staff_id order by payment_date::date) as "Сумма продаж"
from t
group by staff_id, payment_date::date
order by payment_date 


/*Additional task №2
On August 20, 2005, a promotion was held in stores: 
customer of each hundredth payment received an additional discount on the next rental. 
Use the window function to display all customers who received a discount on the day of the promotion*/

 with t as (select *, row_number () over (partition by payment_date::date) as pay_number 
 from payment p
 where payment_date::date = '08-20-2005')
 select
 pay_number, customer_id, c.last_name, c.first_name, amount, payment_date 
 from t
 join customer c using (customer_id)
 where (pay_number % 100)=0


/* Additional task №3
For each country, identify in one SQL query customers that fall under the conditions:
1. customer who rented the most films
2. customer who rented films for the largest amount
3. customer who last rented the film*/

with t as (
	select distinct r.customer_id,
	count (rental_id) over (partition by r.customer_id) as "sum_rentals",
	last_value (rental_date) over (partition by r.customer_id 
		rows between unbounded preceding and unbounded following) as "last_rental_date",
	sum (amount) over (partition by p.customer_id) as "sum_amounts"
	from rental r
	join payment p using (rental_id)
),
t1 as (
	select *,
	row_number () over (partition by country_id order by sum_rentals desc) as "rn_rentals",
	row_number () over (partition by country_id order by last_rental_date desc) as "rn_rdate",
	row_number () over (partition by country_id order by sum_amounts desc) as "rn_amount"
	from t
	join customer c using (customer_id)
	join address a using (address_id)
	join city c2 using (city_id)
	join country c3 using (country_id)
	),
t2 as (
	select country, 
	t1.customer_id 	as "t2cid"
	from t1
	where rn_rentals =1
	),
t3 as (
	select country, 
	t1.customer_id 	as "t3cid"
	from t1
	where rn_amount =1
	),
t4 as (
	select country, 
	t1.customer_id as "t4cid"	
	from t1
	where rn_rdate =1
	)
select 
t1.country,
t2cid as "покупатель, с наибольшим количеством фильмов",
t3cid as "покупатель, с наибольшей суммой",
t4cid as "покупатель, который последним арендовал фильм"
from t1
left join t2 on t1.customer_id = t2cid
left join t3 on t1.customer_id = t3cid
left join t4 on t1.customer_id = t4cid
where t2cid is not null or t3cid is not null or t4cid is not null
order by country


