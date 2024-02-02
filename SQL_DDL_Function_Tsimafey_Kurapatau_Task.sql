create or replace view sales_revenue_by_category_qtr as 
select 
    fc.category_id,
    sum(p.amount) as total_sales_revenue
from 
    film_category fc
    join inventory i on i.film_id = fc.film_id
    join rental r on r.inventory_id = i.inventory_id
    join payment p on p.rental_id = r.rental_id
where 
    extract(quarter from current_date) = extract(quarter from r.rental_date)
    and extract(year from current_date) = extract(year from r.rental_date)
group by 
    fc.category_id
having 
    sum(p.amount) > 0;

drop function if exists get_sales_revenue_by_category_qtr(integer);
---------------
create or replace function get_sales_revenue_by_category_qtr(current_quarter int)
returns table (category text, total_sales numeric) as 
$$
begin
    return query 
    select c.name as category, sum(p.amount) as total_sales 
    from payment p 
    join rental r on p.rental_id = r.rental_id 
    join inventory i on r.inventory_id = i.inventory_id 
    join film_category fc on i.film_id = fc.film_id 
    join category c on fc.category_id = c.category_id 
    where extract(quarter from p.payment_date) = current_quarter
    group by c.name 
    having sum(p.amount) > 0;
end; 
$$ 
language plpgsql;

-------------
create or replace function new_movie(title text)
returns void as $$
declare lang_exists boolean;
begin
    select exists (select 1 from language where name='Klingon') into lang_exists;

    if not lang_exists then raise exception 'Language Klingon does not exist in the database.';
    end if;

    insert into film (title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
        values
        (title, 4.99, 3, 19.99, extract(year from current_date), (select language_id from language where name='Klingon'));
end; $$ language plpgsql;
--------------
select * from sales_revenue_by_category_qtr;
select * from get_sales_revenue_by_category_qtr(1);
insert into language (name) values ('Klingon');
select new_movie('OLETD');
select * from film where title = 'OLETD';