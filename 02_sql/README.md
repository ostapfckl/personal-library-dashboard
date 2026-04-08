![Books by Year](02_sql/books_by_year_avg_price.png)


# Personal Library SQL Analysis

Dataset: personal book library (401 books)  
Database: PostgreSQL  
Purpose: exploratory analysis of book purchases, pricing, and reading habits  

---

## 1 Average book price by year

```sql
SELECT 
    EXTRACT(YEAR FROM purchase_date) AS year,
    COUNT(*) AS total_books,
    ROUND(AVG(price), 2) AS avg_price
FROM library
WHERE price IS NOT NULL
GROUP BY EXTRACT(YEAR FROM purchase_date)
ORDER BY year;
```

Result:

year | total_books | avg_price  
2020 | 3           | 223.67  
2021 | 7           | 210.86  
2022 | 2           | 374.00  
2023 | 115         | 282.68  
2024 | 152         | 363.50  
2025 | 108         | 440.85  
2026 | 13          | 505.00  

![](/02_sql/books_by_year_avg_price.png)

Insight:

Average book prices generally increased over time, especially from 2023 onward.  
The lower averages in 2021 and 2023 should be interpreted carefully because  
yearly results can be influenced by sample size. In particular, 2020–2022  
contain very few books, so those averages are less reliable than the results  
for 2023–2025, where the dataset is much larger.

---

## 2 Year-over-year change in average book price

```sql
WITH yearly_stats AS (
    SELECT 
        EXTRACT(YEAR FROM purchase_date) AS year,
        COUNT(*) AS total_books,
        ROUND(AVG(price), 2) AS avg_price
    FROM library
    WHERE price IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM purchase_date)
    HAVING COUNT(*) > 10
)
SELECT
    year,
    total_books,
    avg_price,
    ROUND(
        (avg_price - LAG(avg_price) OVER (ORDER BY year))
        * 100.0
        / LAG(avg_price) OVER (ORDER BY year),
        2
    ) AS pct_change
FROM yearly_stats
ORDER BY year;
```

Result:

year | total_books | avg_price | pct_change  
2023 | 115         | 282.68    | NULL  
2024 | 152         | 363.50    | 28.59  
2025 | 108         | 440.85    | 21.28  
2026 | 13          | 505.00    | 14.55  

Insight:

After filtering out years with fewer than 10 books, the analysis shows  
a consistent year-over-year increase in average book prices.  
The sharpest increase occurred in 2024 (+28.59%), followed by continued  
growth in 2025 (+21.28%) and 2026 (+14.55%).  

---

## 3 Most expensive books by price per page

```sql
SELECT 
    title,
    author,
    price,
    pages,
    ROUND(price / pages, 3) AS price_per_page
FROM library
WHERE price IS NOT NULL
  AND pages > 0
ORDER BY price_per_page DESC
LIMIT 10;
```

Result:

Top books with highest price per page.

Insight:

Shorter books tend to have higher price per page.

---

## 4 Average price per page by genre

```sql
SELECT 
    genre,
    COUNT(*) AS total_books,
    ROUND(AVG(pages), 0) AS avg_pages,
    ROUND(AVG(price / pages), 3) AS avg_price_per_page
FROM library
WHERE price IS NOT NULL
  AND pages > 0
GROUP BY genre
ORDER BY avg_price_per_page DESC
LIMIT 10;
```

Insight:

Poetry has the highest price per page.

---

## 5 Most expensive vs cheapest publishers

```sql
(SELECT 
    'Most expensive' AS category,
    publisher,
    COUNT(*) AS total_books,
    ROUND(AVG(pages), 0) AS avg_pages,
    ROUND(AVG(price / pages), 3) AS avg_price_per_page
FROM library
WHERE price IS NOT NULL
  AND pages > 0
GROUP BY publisher
HAVING COUNT(*) >= 5
ORDER BY avg_price_per_page DESC
LIMIT 3)

UNION ALL

(SELECT 
    'Cheapest' AS category,
    publisher,
    COUNT(*) AS total_books,
    ROUND(AVG(pages), 0) AS avg_pages,
    ROUND(AVG(price / pages), 3) AS avg_price_per_page
FROM library
WHERE price IS NOT NULL
  AND pages > 0
GROUP BY publisher
HAVING COUNT(*) >= 5
ORDER BY avg_price_per_page
LIMIT 3);
```

Insight:

Price per page differs significantly between publishers.

---

## 6 Reading completion status

```sql
SELECT 
    status,
    COUNT(*) AS total_books,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM library
GROUP BY status
ORDER BY total_books DESC;
```

Insight:

More than half of books are completed.

---

## 7 Top 3 years by purchases

```sql
WITH cte AS (
    SELECT
        EXTRACT(YEAR FROM purchase_date) AS year,
        COUNT(*) AS total_books,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_by_books
    FROM library
    WHERE price IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM purchase_date)
)
SELECT *
FROM cte
WHERE rank_by_books <= 3
ORDER BY rank_by_books;
```

Insight:

2024 is the peak year of purchases.

---

## 8 Completion rate by genre

```sql
SELECT
    genre,
    COUNT(*) AS total_books,
    SUM(CASE WHEN status = 'Прочитано' THEN 1 ELSE 0 END) AS completed_books,
    ROUND(
        SUM(CASE WHEN status = 'Прочитано' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS completion_rate
FROM library
WHERE genre IS NOT NULL
GROUP BY genre
HAVING COUNT(*) >= 5
ORDER BY completion_rate DESC;
```

Insight:

Completion rates differ significantly by genre.

---

## Final Summary

Book prices increased over time.  
Shorter books are more expensive per page.  
Reading behavior varies across genres.
