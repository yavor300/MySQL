1.
CREATE TABLE `pictures` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `url` VARCHAR(100) NOT NULL,
  `added_on` DATETIME NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `categories` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE);

CREATE TABLE `products` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL,
  `best_before` DATE NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `description` TEXT NULL,
  `category_id` INT NOT NULL,
  `picture_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE,
  INDEX `fk_products_categories_idx` (`category_id` ASC) VISIBLE,
  INDEX `fk_products_pictures_idx` (`picture_id` ASC) VISIBLE,
  CONSTRAINT `fk_products_categories`
    FOREIGN KEY (`category_id`)
    REFERENCES `categories` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_products_pictures`
    FOREIGN KEY (`picture_id`)
    REFERENCES `pictures` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE `towns` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE);

CREATE TABLE `addresses` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `town_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE,
  INDEX `fk_addresses_towns_idx` (`town_id` ASC) VISIBLE,
  CONSTRAINT `fk_addresses_towns`
    FOREIGN KEY (`town_id`)
    REFERENCES `towns` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE `stores` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL,
  `rating` FLOAT NOT NULL,
  `has_parking` TINYINT(1) NULL DEFAULT 0,
  `address_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE,
  INDEX `fk_stores_addresses_idx` (`address_id` ASC) VISIBLE,
  CONSTRAINT `fk_stores_addresses`
    FOREIGN KEY (`address_id`)
    REFERENCES `addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE `products_stores` (
  `product_id` INT NOT NULL,
  `store_id` INT NOT NULL,
  PRIMARY KEY (`product_id`, `store_id`),
  INDEX `fk_products_stores_stores_idx` (`store_id` ASC) VISIBLE,
  CONSTRAINT `fk_products_stores_products`
    FOREIGN KEY (`product_id`)
    REFERENCES `products` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_products_stores_stores`
    FOREIGN KEY (`store_id`)
    REFERENCES `stores` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE `employees` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(15) NOT NULL,
  `middle_name` CHAR(1) NULL,
  `last_name` VARCHAR(20) NOT NULL,
  `salary` DECIMAL(19,2) NOT NULL DEFAULT 0,
  `hire_date` DATE NOT NULL,
  `manager_id` INT NULL,
  `store_id` INT NOT NULL,
  PRIMARY KEY (`id`));

ALTER TABLE `employees` 
ADD INDEX `fk_employees_employees_idx` (`manager_id` ASC) VISIBLE,
ADD INDEX `fk_employees_stores_idx` (`store_id` ASC) VISIBLE;

ALTER TABLE `employees` 
ADD CONSTRAINT `fk_employees_employees`
  FOREIGN KEY (`manager_id`)
  REFERENCES `employees` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION,
ADD CONSTRAINT `fk_employees_stores`
  FOREIGN KEY (`store_id`)
  REFERENCES `stores` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;


2.
insert into products_stores(product_id, store_id)
select p.id, 1 from products as p
left join products_stores ps on p.id = ps.product_id
where ps.product_id is null and ps.store_id is null;

3.
update employees
set manager_id = 3, salary = salary - 500
where year(hire_date) > 2003
and store_id != (select id from stores where name = 'Cardguard') and store_id != (select id from stores where name = 'Veribet');

4.
delete from employees
where
manager_id is not null and salary >= 6000;

5.
select first_name, middle_name, last_name, salary, hire_date
from employees
order by hire_date desc;

6.
select name as product_name, price, best_before, concat(substring(description, 1,10), '...') as short_description, p.url
from products
join pictures p on p.id = products.picture_id
where char_length(description) > 100
and year(p.added_on) < 2019
and price > 20
order by price desc;

7.
select s.name, count(pr.id) as product_count, round(avg(pr.price), 2) as avg
from stores as s
left join products_stores ps on s.id = ps.store_id
left join products pr on pr.id = ps.product_id
group by s.id
order by product_count desc, avg desc, s.id;

8.
select concat(e.first_name, ' ', e.last_name) as Full_name, s.name as Store_name, a.name as address, e.salary as salary
from employees as e
join stores s on s.id = e.store_id
join addresses a on a.id = s.address_id
where salary < 7000 and a.name like '%a%' and char_length(s.name) > 5 order by e.id;


9.
select reverse(s.name) as reversed_name, concat(upper(t.name), '-', a.name) as full_address, count(e.id) as employees_count,
       min(p.price) as min_price, count(p.id) as products_count, date_format(max(p2.added_on), '%D-%b-%Y') as newest_pic
from stores as s
left join addresses a on a.id = s.address_id
left join towns t on t.id = a.town_id
left join products_stores ps on s.id = ps.store_id
left join products p on p.id = ps.product_id
left join employees e on ps.store_id = e.store_id
left join pictures p2 on p2.id = p.picture_id
group by reversed_name
having min_price > 10
order by reversed_name, min_price;

10.
create function udf_top_paid_employee_by_store(store_name VARCHAR(50))
    returns TEXT
    deterministic
begin
    declare result TEXT;
    SET result :=
            (select
                 concat(concat(e.first_name, ' ', e.middle_name, '. ', e.last_name), ' works in store for ', TIMESTAMPDIFF(year, e.hire_date, '2020-10-18'), ' years')
                     as result
             from employees e
                      join stores s on s.id = e.store_id
             where s.name = store_name
             group by e.id
             order by max(salary) desc
             limit 1);
    return result;
end 

11.
DELIMITER $$
create procedure udp_update_product_price(address_name VARCHAR(50))
begin
    update products
    join products_stores ps2 on products.id = ps2.product_id
    join stores s2 on s2.id = ps2.store_id
    join addresses a2 on a2.id = s2.address_id
    set price = (
        select
            case
                when products.address_name like '0%' then products.price + 100
                else products.price + 200
                end as price
        from (SELECT a.name as address_name, price FROM products as p
                 join products_stores ps on p.id = ps.product_id
                 join stores s on s.id = ps.store_id
                 join addresses a on s.address_id = a.id
        where a.name = address_name and p.id = products.id) as products
    )
    where a2.name = address_name;
end
$$