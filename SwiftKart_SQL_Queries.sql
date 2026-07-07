# 1) How are customers distributed across different customer segments?
SELECT
    gender,
    COUNT(*) AS total_customers
FROM customers
GROUP BY gender
ORDER BY total_customers DESC;

# 2) How many customers are currently active compared to inactive customers?
SELECT
    active_status,
    COUNT(*) AS total_customers
FROM customers
GROUP BY active_status;

# 3) What is the average revenue generated per customer?
SELECT
    ROUND(AVG(customer_revenue),2) AS average_customer_lifetime_value
FROM
(
    SELECT
        customer_id,
        SUM(net_amount) AS customer_revenue
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
) AS customer_summary;

# 4) Which SwiftKart stores generate the highest revenue?
SELECT
    s.store_name,
    s.city,
    ROUND(SUM(o.net_amount),2) AS total_revenue
FROM stores s
JOIN orders o
ON s.store_id = o.store_id
WHERE o.status = 'Delivered'
GROUP BY s.store_id, s.store_name, s.city
ORDER BY total_revenue DESC
LIMIT 10;

# 5) Which product categories generate the highest revenue?
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.price),2) AS total_revenue
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

# 6) Which products generate the highest revenue for SwiftKart?
SELECT
    p.product_name,
    ROUND(SUM(oi.quantity * oi.price),2) AS total_revenue
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

# 7) Which product categories have the highest average selling price?
SELECT
    category,
    ROUND(AVG(price),2) AS average_price
FROM products
GROUP BY category
ORDER BY average_price DESC;

# 8) Which product categories are ordered most frequently by customers?
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_orders DESC;

# 9) Which products generate the highest profit margin?
SELECT
    product_name,
    category,
    price,
    cost_price,
    ROUND(price - cost_price,2) AS profit_margin
FROM products
ORDER BY profit_margin DESC
LIMIT 10;

# 10) How does weather affect average delivery time?
SELECT
    weather_condition,
    ROUND(AVG(actual_minutes),2) AS average_delivery_time
FROM deliveries d
JOIN orders o
ON o.order_id = d.order_id 
WHERE status='Delivered'
GROUP BY weather_condition
ORDER BY average_delivery_time DESC;

# 11) Which cities have the fastest and slowest deliveries?
SELECT
    s.city,
    ROUND(AVG(d.actual_minutes),2) AS average_delivery_time
FROM deliveries d
JOIN orders o
ON d.order_id = o.order_id
JOIN stores s
ON o.store_id = s.store_id
WHERE o.status='Delivered'
GROUP BY s.city
ORDER BY average_delivery_time;

# 12) Rank customers based on their total spending.
SELECT
    c.customer_id,
    c.full_name,
    SUM(o.net_amount) AS total_spent,
    RANK() OVER (
        ORDER BY SUM(o.net_amount) DESC
    ) AS customer_rank
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.full_name;

# 13) How has revenue changed compared to the previous month?
SELECT
    month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY month) AS previous_month,
    ROUND(
        total_revenue -
        LAG(total_revenue) OVER (ORDER BY month),
        2
    ) AS revenue_growth
FROM
(
    SELECT
        DATE_FORMAT(order_timestamp,'%Y-%m') AS month,
        SUM(net_amount) AS total_revenue
    FROM orders
    WHERE status='Delivered'
    GROUP BY month
) t;

# 14) How does cumulative revenue grow over time?
SELECT
    DATE(order_timestamp) AS order_date,
    SUM(net_amount) AS daily_revenue,
    SUM(SUM(net_amount))
        OVER (
            ORDER BY DATE(order_timestamp)
        ) AS cumulative_revenue
FROM orders
WHERE status='Delivered'
GROUP BY DATE(order_timestamp);

# 15) Which product generates the highest revenue within each category?
SELECT *
FROM
(
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity*oi.price) AS revenue,
        ROW_NUMBER() OVER(
            PARTITION BY p.category
            ORDER BY SUM(oi.quantity*oi.price) DESC
        ) AS rn
    FROM products p
    JOIN order_items oi
    ON p.product_id=oi.product_id
    GROUP BY p.category,p.product_name
) t
WHERE rn=1;