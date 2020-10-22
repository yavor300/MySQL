-------------------1-----------------
CREATE PROCEDURE usp_get_employees_salary_above_35000()
BEGIN
	SELECT e.first_name, e.last_name
    FROM employees AS e
    WHERE e.salary > 35000
    ORDER BY e.first_name, e.last_name;
END
-------------------2----------------- 
CREATE PROCEDURE usp_get_employees_salary_above(salary_level DECIMAL(19,4))
BEGIN
    SELECT e.first_name, e.last_name
    FROM employees AS e
    WHERE e.salary >= salary_level
    ORDER BY e.first_name, e.last_name;
END
-------------------3-----------------
CREATE PROCEDURE usp_get_towns_starting_with(check_text VARCHAR(50))
BEGIN
    SELECT t.name
    FROM towns AS t
    WHERE LOWER(SUBSTRING(t.name, 1, CHAR_LENGTH(check_text))) = LOWER(check_text)
    ORDER BY t.name;
END
-------------------4----------------- 
CREATE PROCEDURE usp_get_employees_from_town  (input_town VARCHAR(20))
BEGIN

SELECT e.first_name, e.last_name 
      FROM employees AS e, towns AS t, addresses AS a
WHERE input_town = t.name AND t.town_id = a.town_id AND a.address_id = e.address_id
ORDER BY e.first_name, e.last_name;

END
-------------------5----------------- 
DELIMITER $$
CREATE FUNCTION ufn_get_salary_level(salary DECIMAL(19,4))
RETURNS VARCHAR(10)

BEGIN
   DECLARE salary_level VARCHAR(10);
   
   IF (salary < 30000) THEN SET salary_level = 'Low';
   ELSEIF(salary >= 30000 AND salary <= 50000) THEN SET salary_level = 'Average';
   ELSEIF(salary > 50000) THEN SET salary_level = 'High';
   END IF;
   
   RETURN salary_level;
   
END $$
DELIMITER ;

-- select e.first_name,last_name,salary,
-- ufn_get_salary_level(salary) as 'salary_level'
-- from employees as e

-------------------6----------------- 
CREATE PROCEDURE usp_get_employees_by_salary_level(salary_level VARCHAR(7))
BEGIN
	SELECT e.first_name, e.last_name FROM employees AS e
    INNER JOIN (SELECT e.employee_id,e.salary, 
	 CASE WHEN e.salary < 30000 THEN 'Low' 
	      WHEN e.salary BETWEEN 30000 AND 50000 THEN 'Average' 
			WHEN e.salary > 50000 THEN 'High' 
			END 
			AS 'salary_level' FROM employees AS e) AS sl
    ON e.employee_id = sl.employee_id
    WHERE salary_level = sl.salary_level
    ORDER BY e.first_name DESC, e.last_name DESC;
END
-------------------7-----------------  
create function ufn_is_word_comprised (set_of_chars varchar(30),word varchar(200)) returns bool
begin
       declare len int default CHAR_LENGTH(word);
       declare idx int default 1;
       while idx <= len
       do
          if locate(SUBSTRING(word,idx,1),set_of_chars) < 1
          then
            return false;
          end if;
          set idx = idx + 1;
		 end while;
	return true;	        
end
-------------------8----------------- 
DELETE FROM employees_projects
WHERE employees_projects.employee_id IN
(
	SELECT e.employee_id
	FROM employees AS `e`
	WHERE e.department_id = (SELECT d.department_id FROM departments AS `d` WHERE(d.name = 'Production'))
	OR e.department_id = (SELECT d.department_id FROM departments AS `d` WHERE(d.name = 'Production Control'))
);

UPDATE employees AS `e`
SET e.manager_id = NULL
WHERE e.department_id = (SELECT d.department_id FROM departments AS `d` WHERE(d.name = 'Production'))
OR e.department_id = (SELECT d.department_id FROM departments AS `d` WHERE(d.name = 'Production Control'));

ALTER TABLE departments
MODIFY COLUMN manager_id INT NULL;

UPDATE departments AS `d`
SET d.manager_id = NULL
WHERE(d.name = 'Production' or d.name = 'Production Control');

ALTER TABLE employees
DROP FOREIGN KEY fk_employees_employees;

DELETE FROM employees
WHERE employees.department_id = (SELECT d.department_id FROM departments AS `d` WHERE(d.name = 'Production'))
OR employees.department_id = (SELECT d.department_id FROM departments AS `d` WHERE(d.name = 'Production Control'));

DELETE FROM departments
WHERE (name = 'Production' OR name = 'Production Control');
-------------------9-----------------
CREATE PROCEDURE usp_get_holders_full_name()
BEGIN
	SELECT CONCAT_WS(' ', a.first_name, a.last_name) AS 'full_name'
	FROM account_holders AS a
	ORDER BY a.first_name, a.last_name;
END
-------------------10----------------- 
CREATE PROCEDURE usp_get_holders_with_balance_higher_than(total_amount DECIMAL(19,4))
BEGIN
	SELECT total_balance.first_name, total_balance.last_name
	FROM
	(SELECT ah.first_name, ah.last_name, SUM(a.balance) as `sum`
	FROM `account_holders` AS ah
	INNER JOIN `accounts` AS a
	ON ah.id = a.account_holder_id
	GROUP BY ah.first_name, ah.last_name) as total_balance
	WHERE total_balance.`sum` > total_amount
	ORDER BY total_balance.first_name, total_balance.last_name;
END 
-------------------11----------------- 
CREATE FUNCTION ufn_calculate_future_value(initial_sum DECIMAL(19,2), yearly_interest_rate DECIMAL(19,2), number_of_years INT)
  RETURNS DECIMAL(19,2)
  BEGIN
    DECLARE future_value DECIMAL(19, 2);
    SET future_value := (initial_sum * (POW((1 + yearly_interest_rate), number_of_years)));
    RETURN future_value;
  END;
-------------------12----------------- 
CREATE PROCEDURE usp_calculate_future_value_for_account (account_id INT, interest_rate DECIMAL(19,4))

BEGIN

  DECLARE future_value DECIMAL(19,4);

  DECLARE balance DECIMAL(19, 4);

  SET balance := (SELECT a.balance FROM accounts AS a WHERE a.id = account_id);

  SET future_value := balance * (POW((1 + interest_rate), 5));

  SELECT a.id AS account_id, ah.first_name, ah.last_name, a.balance, future_value

    FROM accounts AS a

   INNER JOIN account_holders AS ah

      ON a.account_holder_id = ah.id

     AND a.id = account_id;

END;
-------------------13----------------- 
drop procedure if exists usp_deposit_money;
DELIMITER $$
create procedure usp_deposit_money(IN account_id INT,IN money_amount DECIMAL(19,4))
begin
    start transaction;
    update accounts set accounts.balance = accounts.balance + money_amount
    where accounts.id = account_id;    
    
    if money_amount <= 0
    then 
	    ROLLBACK;
    else
       COMMIT;
    end if;

end$$
DELIMITER  ; 

call usp_deposit_money(1,100);
select*from accounts as a where a.id = 1; 
-------------------14----------------- 
delimiter $$
create procedure usp_withdraw_money  (IN account_id INT, IN money_amount DECIMAL(19,4))
begin
start transaction;
	UPDATE accounts SET accounts.balance = accounts.balance-money_amount
	WHERE accounts.id = account_id;	

 if((select a1.balance from accounts as `a1` where account_id = a1.id) < 0)
  then rollback;
 end if;
 if(money_amount <= 0 or account_id > 18 or account_id < 1) 
 then rollback;
 end if;
commit;	
END $$ 
delimiter;
-------------------15-----------------
CREATE PROCEDURE usp_transfer_money(from_account_id INT, to_account_id INT, amount DECIMAL(19,4)) 
BEGIN
	START TRANSACTION;
		UPDATE accounts SET balance = balance - amount
			WHERE id = from_account_id;
			UPDATE accounts SET balance = balance + amount
			WHERE id = to_account_id;
			
		IF((SELECT COUNT(*) FROM accounts
		      WHERE id = from_account_id) <> 1)
		   THEN ROLLBACK;
		ELSEIF(amount > (SELECT balance FROM accounts WHERE id = from_account_id))
			THEN ROLLBACK;
		ELSEIF(amount <= 0)
			THEN ROLLBACK;
		ELSEIF((SELECT balance FROM accounts WHERE id = from_account_id) <= 0)
			THEN ROLLBACK;	
		ELSEIF((SELECT COUNT(*) FROM accounts
		      WHERE id = to_account_id) <> 1)
		   THEN ROLLBACK;
		ELSEIF(amount <= 0)
			THEN ROLLBACK;
		ELSEIF(from_account_id = to_account_id)
			THEN ROLLBACK;
		ELSE 
			COMMIT;
		END IF;

END
-------------------16----------------- 
create table logs 
(
	log_id INT AUTO_INCREMENT PRIMARY KEY, 
	account_id INT, 
	old_sum DECIMAL(19,4), 
	new_sum DECIMAL(19,4)
); 

CREATE TRIGGER after_accounts_update
AFTER UPDATE 
ON accounts
FOR EACH ROW
BEGIN
	INSERT INTO logs (account_id, old_sum, new_sum)
	VALUES (OLD.id, OLD.balance, NEW.balance);
END
-------------------17----------------- 
CREATE TABLE logs(
	log_id INT AUTO_INCREMENT PRIMARY KEY,
	account_id INT,
	old_sum DECIMAL(19,4),
	new_sum DECIMAL(19, 4)
);
CREATE TABLE notification_emails(
	id INT AUTO_INCREMENT PRIMARY KEY,
	recipient INT,
	subject VARCHAR(50),
	body TEXT
);
CREATE TRIGGER tr_emails
AFTER UPDATE
ON accounts
FOR EACH ROW 
BEGIN
	INSERT INTO logs(account_id, old_sum, new_sum)
	VALUES(old.id, old.balance, new.balance);
	INSERT INTO notification_emails(recipient, subject, body)
	VALUES(
		old.id,
		CONCAT_WS(': ', 'Balance change for account', old.id),
		CONCAT('On ', NOW(), ' your balance was changed from ', old.balance, ' to ', new.balance, '.' ));
END