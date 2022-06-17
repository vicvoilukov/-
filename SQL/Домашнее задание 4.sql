-- Task 1
-- Design a database containing three directories:
-- language (English, French, etc.);
-- nationality (Slavs, Anglo-Saxons, etc.);
-- countries (Russia, Germany, etc.).
-- Two tables with relation: language-ethnicity and nationality-country, 
-- many-to-many relationships. An example of a table with relationships is film_actor.
--Requirements for reference tables:
-- The presence of primary key constraints.
-- entity identifier must be assigned by autoincrement;
-- Entity names should not contain null values, duplicates in entity names should not be allowed.
-- Requirements for tables with links:
-- The presence of constraints on primary and foreign keys.

create schema Homework_4

-- Language table
create table "language_new" (
language_id serial primary key,
language varchar(50) unique not null, 
last_update timestamp default now ()
);

insert into language_new (language)
select distinct language.name from language

insert into language_new (language)
values ('Russian')

select * from language_new ;

-- Nationality table
create table "nationality"
(nationality_id serial primary key,
name varchar (50) not null,
last_update timestamp default now ()
);

insert into nationality (name)
values ('Anglo-Saxons'), ('Slavs'), ('Chinese'), ('Japanese')

select * from nationality ;


-- Countries table
create table "country_new" (
country_id serial primary key,
country varchar(50) not null, 
last_update timestamp default now ()
);

insert into country_new (country)
select distinct country from public.country

delete from country_new 
where country_id >=7

select * from country_new 

-- Relation table language-ethnicity
create table "language_nation" (
l_id integer references language_new (language_id),
n_id integer references nationality (nationality_id),
primary key (l_id,n_id)
);

select * from language_nation ;

insert into language_nation (l_id, n_id)
values (1, 1), (2, 1), (3, 1), (4, 3), (5, 4), (6, 1), (7, 2)

-- Relation table nationality-country
create table "nation_country" (
c_id integer references country_new (country_id),
n_id integer references nationality (nationality_id),
primary key (c_id,n_id)
);

insert into nation_country (n_id, c_id)
values (3, 1), (1, 2), (3, 3), (1, 4), (3, 5), (1, 6)

select * from nation_country ;

drop table nation_country


-- Additional part

-- additional task 1
-- create a new table film_new with all users:
-- film_name — film name — data type varchar(255) and name not null;
-- film_year — film release year — integer data type, conditions that the value must be greater than 0;
-- film_rental_rate — film rental cost — data type numeric(4,2), default value 0.99;
-- film_duration - the duration of the film in minutes
-- an integer data type, the value of which is not null, and the value of which must be greater than 0.

create table "film_new" (
film_id serial primary key, 
film_name varchar(255) not null, 
film_year integer check (film_year > 0),
film_rental_rate numeric (4,2) default 0.99,
film_duration integer not null check (film_duration > 0)
);

select * from film_new fn 

-- Additional task 2
-- Fill the film_new table with data using an SQL query, where the columns correspond to data arrays:
-- film_name — array[The Shawshank Redemption, The Green Mile, Back to the Future, Forrest Gump, Schindler’s List];
-- film_year — array[1994, 1999, 1985, 1994, 1993];
-- film_rental_rate — array[2.99, 0.99, 1.99, 2.99, 3.99];
-- film_duration — array[142, 189, 116, 142, 195].

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
select unnest (array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
unnest (array[1994, 1999, 1985, 1994, 1993]),
unnest (array[2.99, 0.99, 1.99, 2.99, 3.99]),
unnest (array[142, 189, 116, 142, 195])

select * from film_new ;

-- Additional task 3
-- Update the film rental rates in the film_new table to reflect that all film rentals have increased by 1.41.

update film_new 
set film_rental_rate = (film_rental_rate + 1.41)

-- Additional task 4
-- A movie called 'Back to the Future' has been rented out, remove the row with this movie from the film_new table.

delete from film_new 
where film_name = 'Back to the Future'

select * from film_new fn 

-- Additional task 5
-- Add an entry to the film_new table for any other new film.

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
select title, release_year, rental_rate, length from public.film
where film_id = 13

select * from film_new fn 

-- Additional task 6
-- Write a SQL query that will display all the columns from the film_new, 
-- also the new calculated column "length of the film in hours", rounded up to tenths.

alter table film_new add column film_duration_h numeric (4,1)

update film_new 
set film_duration_h = (film_duration::numeric /60)

-- Additional task 7
-- Delete film_new table.

drop table film_new 
