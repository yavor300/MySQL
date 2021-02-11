CREATE SCHEMA `insta_influencers_db`;

----------------1-------------------------

CREATE TABLE `users`(
  `id` INT PRIMARY KEY NOT NULL,
  `username` VARCHAR(30) NOT NULL,
  `password` VARCHAR(30) NOT NULL,
  `email` VARCHAR(50) NOT NULL,
  `gender` CHAR(1) NOT NULL,
  `age` INT NOT NULL,
  `job_title` VARCHAR(40) NOT NULL,
  `ip` VARCHAR(30) NOT NULL
);

CREATE TABLE `addresses` (
  `id` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `address` VARCHAR(30) NOT NULL,
  `town` VARCHAR(30) NOT NULL,
  `country` VARCHAR(30) NOT NULL,
  `user_id` INT NOT NULL,
  CONSTRAINT `fk_addresses_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users`(`id`)
);

CREATE TABLE `photos` (
  `id` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `description` TEXT NOT NULL,
  `date` DATETIME NOT NULL,
  `views` INT NOT NULL DEFAULT 0
 );


CREATE TABLE `comments` (
  `id` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `comment` VARCHAR(255) NOT NULL,
  `date` DATETIME NOT NULL,
  `photo_id` INT NOT NULL,
  CONSTRAINT `fk_comments_photos`
    FOREIGN KEY (`photo_id`)
    REFERENCES `photos` (`id`)
 );


CREATE TABLE `users_photos` (
  `user_id` INT NOT NULL,
  `photo_id` INT NOT NULL,
  PRIMARY KEY (`user_id`, `photo_id`),
  CONSTRAINT `fk_users_photos_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`),
  CONSTRAINT `fk_users_photos_photos`
    FOREIGN KEY (`photo_id`)
    REFERENCES `photos` (`id`)
);

CREATE TABLE `likes` (
  `id` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `photo_id` INT NULL,
  `user_id` INT NULL,
  CONSTRAINT `fk_likes_photos`
    FOREIGN KEY (`photo_id`)
    REFERENCES `photos`(`id`),
  CONSTRAINT `fk_likes_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users`(`id`)
);


--------------------2------------------------



INSERT INTO `addresses`(`address`, `town`, `country`, `user_id`)
SELECT u.`username`, u.`password`, u.`ip`, u.`age`
FROM `users` AS u
WHERE u.`gender` = 'M';



-------------------3-----------------------


UPDATE `addresses`
SET `country` = (
	CASE
		WHEN LEFT(`country`, 1) = "B" THEN "Blocked"
        	WHEN LEFT(`country`, 1) = "T" THEN "Test"
        	WHEN LEFT(`country`, 1) = "P" THEN "In Progress"
        	ELSE `country`
	END
);


---------------------4-----------------------

DELETE FROM `addresses`
WHERE `id` % 3 = 0;


---------------------5--------------------


SELECT `username`, `gender`, `age`
FROM `users`
ORDER BY `age` DESC, `username` ASC;


---------------------6----------------------

SELECT p.`id`, p.`date` AS `date_and_time`, p.`description`, COUNT(c.`comment`) AS `commentsCount`
FROM `photos` AS p
JOIN `comments` AS c
ON  p.`id` = c.`photo_id` 
GROUP BY p.`id`
ORDER BY `commentsCount` DESC, p.`id` ASC
LIMIT 5; 


----------------------------------------7---------------------------------------------------------------

SELECT CONCAT(u.`id`, ' ', u.`username`) AS `id_username`, u.`email`
FROM `users` AS u
JOIN `users_photos` AS up
ON u.`id` = up.`user_id`
JOIN `photos` AS p
ON up.`photo_id` = p.`id`
WHERE u.`id` = p.`id`
ORDER BY u.`id` ASC;

-----------------------------------------8-------------------------------------

SELECT p.`id`, (
	SELECT COUNT(l.`id`)
    FROM `likes` AS l
    WHERE l.`photo_id` = p.`id`
) 
AS `likes_count`,
(
	SELECT COUNT(c.`id`)
    FROM `comments` AS c
    WHERE c.`photo_id` = p.`id`
)
AS `comments_count`
FROM `photos` AS p
GROUP BY p.`id`
ORDER BY `likes_count` DESC, `comments_count` DESC, p.`id` ASC;

--------------------------------------------9------------------------------------------------


SELECT CONCAT(LEFT(p.`description`, 30), "", "...") AS `summary`, p.`date`
FROM `photos` AS p
WHERE DAY(p.`date`) = 10
ORDER BY p.`date` DESC;
