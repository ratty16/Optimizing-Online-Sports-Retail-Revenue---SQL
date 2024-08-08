-- 1. Counting missing values

SELECT COUNT(info) as total_rows,
       COUNT(info.description) as count_description, 
       COUNT(finance.listing_price) as count_listing_price,
       COUNT(traffic.last_visited) as count_last_visited
FROM info
INNER JOIN traffic ON traffic.product_id = info.product_id
INNER JOIN finance ON finance.product_id = info.product_id;

-- 2. Nike vs Adidas pricing

SELECT brands.brand, 
       CAST(finance.listing_price AS INTEGER) AS listing_price, 
       COUNT(finance.product_id) AS count
FROM brands
INNER JOIN finance ON finance.product_id = brands.product_id
WHERE finance.listing_price > 0
GROUP BY brands.brand, finance.listing_price
ORDER BY finance.listing_price DESC;

-- 3. Labeling price ranges

SELECT b.brand, 
       COUNT(f.*) AS product_count, 
       SUM(f.revenue) AS total_revenue,
       CASE 
           WHEN f.listing_price < 42 THEN 'Budget'
           WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
           WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
           ELSE 'Elite'
       END AS price_category
FROM finance AS f
INNER JOIN brands AS b ON f.product_id = b.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand, price_category
ORDER BY total_revenue DESC;

-- 4. Average listing price per product by brand

SELECT b.brand, 
       AVG(f.listing_price) AS average_listing_price
FROM brands AS b
INNER JOIN finance AS f ON b.product_id = f.product_id
GROUP BY b.brand
ORDER BY average_listing_price DESC;

-- 5. Correlation between revenue and reviews

SELECT CORR(reviews.reviews, revenue) AS review_revenue_corr
FROM reviews
INNER JOIN finance ON finance.product_id = reviews.product_id;

-- 6. Ratings and reviews by product description length

SELECT TRUNC(LENGTH(i.description), -2) AS description_length,
       ROUND(AVG(r.rating::numeric), 2) AS average_rating
FROM info AS i
INNER JOIN reviews AS r ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;

-- 7. Reviews by month and brand

SELECT b.brand, 
       DATE_PART('month', t.last_visited) AS month, 
       COUNT(r.*) AS num_reviews
FROM brands AS b
INNER JOIN traffic AS t ON b.product_id = t.product_id
INNER JOIN reviews AS r ON t.product_id = r.product_id
GROUP BY b.brand, month
HAVING b.brand IS NOT NULL
    AND DATE_PART('month', t.last_visited) IS NOT NULL
ORDER BY b.brand, month;

-- 8. Footwear product performance

WITH footwear AS (
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f ON i.product_id = f.product_id
    WHERE i.description ILIKE '%shoe%'
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%'
        AND i.description IS NOT NULL
)
SELECT COUNT(*) AS num_footwear_products, 
       percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median_footwear_revenue
FROM footwear;

-- 9. Clothing product performance

WITH footwear AS (
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f ON i.product_id = f.product_id
    WHERE i.description ILIKE '%shoe%'
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%'
        AND i.description IS NOT NULL
)
SELECT COUNT(i.*) AS num_clothing_products, 
       percentile_disc(0.5) WITHIN GROUP (ORDER BY f.revenue) AS median_clothing_revenue
FROM info AS i
INNER JOIN finance AS f ON i.product_id = f.product_id
WHERE i.description NOT IN (SELECT description FROM footwear);

