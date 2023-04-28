CREATE SCHEMA dannys_diner;
--SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);
 

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT S.customer_id, CONCAT(SUM(M.price), ' $') AS Total_Spent
FROM sales S INNER JOIN menu M
ON S.product_id = M.product_id
GROUP BY S.customer_id 



-- 2. How many days has each customer visited the restaurant?

SELECT S.customer_id, COUNT(DISTINCT(S.order_date)) AS Num_Visited
FROM sales S
GROUP BY S.customer_id 



-- 3. What was the first item from the menu purchased by each customer?

SELECT DISTINCT NEW.customer_id, NEW.order_date, NEW.product_id, M.product_name
FROM (SELECT S.customer_id, S.order_date, S.product_id,
     DENSE_RANK()OVER(PARTITION BY S.customer_id ORDER BY S.order_date) R 
     FROM sales S) AS NEW INNER JOIN menu M 
	 ON NEW.product_id = M.product_id
WHERE R = 1



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 COUNT(S.Product_id) AS NUM, M.product_name
FROM sales S INNER JOIN menu M
ON S.product_id = M.product_id
GROUP BY  M.product_name
ORDER BY COUNT(S.Product_id) DESC



-- 5. Which item was the most popular for each customer?

WITH M_P
AS
(
SELECT S.customer_id, S.Product_id , RANK()OVER(PARTITION BY S.customer_id ORDER BY COUNT(S.Product_id) DESC) R
     FROM sales S 
	 GROUP BY S.customer_id, S.Product_id
)
SELECT mp.customer_id, STRING_AGG(cast(mp.Product_id as varchar(10)),', ') as Product_ID
      , STRING_AGG(M.product_name, ', ') AS Product_Name
FROM M_P mp INNER JOIN menu M
ON mp.product_id = M.product_id
WHERE R = 1
GROUP BY mp.customer_id;


-- 6. Which item was purchased first by the customer after they became a member?

WITH C_Member
AS
(
 SELECT M.customer_id, S.order_date, S.product_id , 
 RANK()OVER(PARTITION BY S.customer_id ORDER BY S.order_date ) R
 FROM sales S INNER JOIN members M
 ON S.customer_id = M.customer_id
 WHERE M.join_date <= S.order_date 
)

SELECT CM.customer_id, CM.order_date, CM.product_id, ME.product_name
FROM C_Member CM INNER JOIN menu ME
ON ME.product_id = CM.product_id
WHERE R = 1


-- 7. Which item was purchased just before the customer became a member?

WITH C_Member
AS
(
 SELECT M.customer_id, S.order_date, S.product_id , 
 RANK()OVER(PARTITION BY S.customer_id ORDER BY S.order_date DESC ) R
 FROM sales S INNER JOIN members M
 ON S.customer_id = M.customer_id
 WHERE M.join_date > S.order_date 
)

SELECT CM.customer_id, CM.order_date, CM.product_id, ME.product_name
FROM C_Member CM INNER JOIN menu ME
ON ME.product_id = CM.product_id
WHERE R = 1



-- 8. What is the total items and amount spent for each member before they became a member?

SELECT S.customer_id, COUNT(S.product_id) AS total_items, CONCAT(SUM(MU.price), ' $') AS amount_spent
FROM sales S INNER JOIN members M
ON S.customer_id = M.customer_id
INNER JOIN menu MU
ON MU.product_id = S.product_id
WHERE S.order_date < M.join_date
GROUP BY S.customer_id



-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT S.customer_id, SUM( 
  CASE
  WHEN S.product_id = 1 THEN 2*10*MU.price
  ELSE 10*MU.price
  END) AS Total_Points
FROM sales S INNER JOIN menu MU
ON MU.product_id = S.product_id
GROUP BY S.customer_id;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


SELECT S.customer_id ,SUM(
   CASE
   WHEN M.join_date <= S.order_date AND order_date  BETWEEN M.join_date AND DATEADD(WEEK, 1, M.join_date)  THEN MU.price*2*10
   ELSE MU.price*10
   END) AS Total_Points
FROM sales S INNER JOIN members M
 ON S.customer_id = M.customer_id
 INNER JOIN menu MU
ON MU.product_id = S.product_id
WHERE order_date <= '2021-01-31'
GROUP BY S.customer_id;



--------------------Bonus Questions--------------------
--1 Join All The Things

SELECT S.customer_id, S.order_date, MU.product_name, MU.price 
  ,CASE 
   WHEN M.join_date <= S.order_date THEN 'Y'
   ELSE 'N'
   END
FROM sales S LEFT JOIN members M
 ON S.customer_id = M.customer_id
 INNER JOIN menu MU
ON MU.product_id = S.product_id


--2 Rank All The Things

WITH Y_N
AS
(
 SELECT S.customer_id, S.order_date, MU.product_name, MU.price 
  ,CASE 
   WHEN M.join_date <= S.order_date THEN 'Y'
   ELSE 'N'
   END AS member
 FROM sales S LEFT JOIN members M
  ON S.customer_id = M.customer_id
  INNER JOIN menu MU
 ON MU.product_id = S.product_id
)

--SELECT *, RANK()OVER(PARTITION BY customer_id ORDER BY order_date, CASE WHEN member = 'Y' THEN 1 ELSE NULL END ) AS rank
SELECT * , CASE WHEN member = 'Y' THEN RANK()OVER(PARTITION BY customer_id,member ORDER BY order_date) ELSE NULL END AS ranking
FROM Y_N