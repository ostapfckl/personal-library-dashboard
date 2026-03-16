-- Personal Library SQL Analysis
-- Dataset: personal book library (401 books)
-- Database: PostgreSQL
-- Purpose: exploratory analysis of book purchases, pricing, and reading habits

--==================================================================================

-- 1 Average book price by year
SELECT 
    EXTRACT(YEAR FROM purchase_date) AS year,
    COUNT(*) AS total_books,
    ROUND(AVG(price), 2) AS avg_price
FROM library
WHERE price IS NOT NULL
GROUP BY EXTRACT(YEAR FROM purchase_date)
ORDER BY year;

-- Result:
-- year | total_books | avg_price
-- 2020 | 3           | 223.67
-- 2021 | 7           | 210.86
-- 2022 | 2           | 374.00
-- 2023 | 115         | 282.68
-- 2024 | 152         | 363.50
-- 2025 | 108         | 440.85
-- 2026 | 13          | 505.00

-- Insight:
-- Average book prices generally increased over time, especially from 2023 onward.
-- The lower averages in 2021 and 2023 should be interpreted carefully because
-- yearly results can be influenced by sample size. In particular, 2020–2022
-- contain very few books, so those averages are less reliable than the results
-- for 2023–2025, where the dataset is much larger.

--===================================================================================

-- 2 Year-over-year change in average book price
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

-- Result:
-- year | total_books | avg_price | pct_change
-- 2023 | 115         | 282.68    | NULL
-- 2024 | 152         | 363.50    | 28.59
-- 2025 | 108         | 440.85    | 21.28
-- 2026 | 13          | 505.00    | 14.55

-- Insight:
-- After filtering out years with fewer than 10 books, the analysis shows
-- a consistent year-over-year increase in average book prices.
-- The sharpest increase occurred in 2024 (+28.59%), followed by continued
-- growth in 2025 (+21.28%) and 2026 (+14.55%).
-- This suggests that book prices in the library have been rising steadily,
-- although the smaller sample size in 2026 should still be interpreted with caution.

--======================================================================================

-- 3 Most expensive books by price per page
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

-- Result:
-- title                          | author                  | price | pages | price_per_page
-- Тіні забутих предків           | Михайло Коцюбинський    | 395   | 136   | 2.904
-- 30 віршів про любов і залізницю| Сергій Жадан            | 228   | 88    | 2.591
-- Тільки не пиши мені про війну  | Павло Вишебаба          | 295   | 120   | 2.458
-- Список кораблів                | Сергій Жадан            | 360   | 160   | 2.250
-- Племʼя                         | Себастьян Юнґер         | 270   | 128   | 2.109
-- Таємниці маєтку шипів          | Марґарет Роджерсон      | 300   | 144   | 2.083
-- Конклав                        | Пенелопа Дуглас         | 225   | 112   | 2.009
-- Радуйся жінко                  | Мар'яна Савка           | 180   | 96    | 1.875
-- Тамплієри                      | Сергій Жадан            | 225   | 120   | 1.875
-- Знайди мене                    | Тагере Мафі             | 300   | 160   | 1.875

-- Insight:
-- Books with the highest price-per-page ratios in the dataset are mostly shorter titles,
-- including poetry collections and literary editions.
-- This suggests that shorter books are often relatively more expensive per page.

--========================================================================================

-- 4 Average price per page by genre

-- Hypothesis:
-- In the previous analysis we observed that shorter books tend to have a higher
-- price per page. Since poetry collections are typically shorter than novels,
-- we expect poetry to have one of the highest price-per-page values among genres.

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

-- Result:
-- genre                | total_books | avg_pages | avg_price_per_page
-- Поезія               | 9           | 196       | 1.760
-- Нон-фікшн            | 7           | 278       | 1.210
-- Українська класика   | 7           | 330       | 1.200
-- Ромком               | 3           | 299       | 1.198
-- Манга                | 3           | 157       | 1.164
-- Мафія                | 2           | 443       | 1.044
-- Біографічна проза    | 3           | 362       | 1.006
-- Даркроман            | 8           | 497       | 0.974
-- Любовний роман       | 94          | 405       | 0.972
-- Спортивний роман     | 24          | 479       | 0.962

-- Insight:
-- The hypothesis is confirmed. Poetry has the highest average price per page
-- in the dataset (1.760) and also one of the lowest average page counts.
-- Genres with longer books, such as romance or sports novels, tend to have
-- a lower price per page. This suggests that shorter literary formats
-- are relatively more expensive per page than longer narrative works.

--=========================================================================

-- 5 Most expensive vs cheapest publishers by price per page

-- Hypothesis:
-- If price per page differs significantly between publishers,
-- some publishers may systematically produce more expensive
-- books relative to their length.

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

-- Result:
-- category        | publisher             | total_books | avg_pages | avg_price_per_page
-- Most expensive  | Meridian Czernowitz   | 7           | 288       | 1.409
-- Most expensive  | Артбукс               | 6           | 413       | 1.139
-- Most expensive  | Readberry             | 27          | 433       | 1.128
-- Cheapest        | Ранок                 | 9           | 524       | 0.586
-- Cheapest        | BookChef              | 24          | 509       | 0.595
-- Cheapest        | Фоліо                 | 11          | 296       | 0.652

-- Insight:
-- Price per page differs significantly between publishers.
-- The most expensive publisher (Meridian Czernowitz: 1.409 per page)
-- is about 2.4x more expensive than the most affordable one
-- (Ranok: 0.586 per page).
-- This difference is not explained by page count alone and may also be
-- influenced by factors such as print quality, edition format,
-- publisher niche, or discounts applied at the time of purchase.

--==========================================================================================

-- 6 Reading completion status distribution

-- Hypothesis:
-- Understanding how many books are actually read can reveal reading
-- behavior patterns and the effectiveness of book purchases.

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

-- Result:
-- status        | total_books | percentage
-- Прочитано     | 210         | 52.37
-- Не прочитано  | 176         | 43.89
-- Почато        | 14          | 3.49
-- Закинуто      | 1           | 0.25

-- Insight:
-- Slightly more than half of the books in the library have been completed (52.37%),
-- while 43.89% remain unread. Only a very small share of books are currently
-- in progress (3.49%) or abandoned (0.25%).
--
-- The large number of unread books humorously suggests that buying books
-- and reading them might actually be two different hobbies.

--=================================================================================

-- 7 Top 3 years by number of books purchased

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

-- Result:
-- year | total_books | rank_by_books
-- 2024 | 152         | 1
-- 2023 | 115         | 2
-- 2025 | 108         | 3

-- Insight:
-- The library grew most actively in 2024, which ranks first by number of books purchased.
-- Together, 2023–2025 stand out as the core growth period of the collection,
-- suggesting that these years represent the most active phase of building the home library.

--=================================================================================

-- 8 Completion rate by genre

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

-- Result:
-- genre                | total_books | completed_books | completion_rate
-- Спортивний роман     | 24          | 24              | 100.00
-- Антиутопія           | 5           | 4               | 80.00
-- Даркроман            | 9           | 7               | 77.78
-- Любовний роман       | 94          | 63              | 67.02
-- Фентезі              | 139         | 72              | 51.80
-- Сучасна проза        | 59          | 24              | 40.68
-- Українська класика   | 7           | 1               | 14.29
-- Нон-фікшн            | 7           | 1               | 14.29
-- Класика              | 17          | 2               | 11.76
-- Поезія               | 9           | 1               | 11.11

-- Insight:
-- Completion rate helps identify the genres that are most consistently finished.
-- Sports novels show the highest completion rate, followed by dystopian and dark
-- romance titles. Romance and fantasy also have relatively strong completion
-- rates while representing a large share of the library.
--
-- In contrast, poetry, classics, and non-fiction have much lower completion rates,
-- suggesting that these genres are finished less frequently.


--=================================================================================
-- Final Summary

-- The analysis explores pricing trends, reading behavior, and structural
-- characteristics of a personal library dataset containing 401 books.

-- Key findings:
-- Book prices in the collection have generally increased over time,
-- especially after 2023.

-- Shorter books, particularly poetry collections, tend to have a higher
-- price per page compared to longer narrative works.

-- Price per page varies significantly between publishers, with some
-- publishers producing books that are more expensive relative to their length.

-- Slightly more than half of the books in the library have been completed,
-- while a large share remains unread.

-- Completion rates also differ between genres, helping identify which
-- types of books are most consistently finished.

-- Overall, the analysis shows how a personal library can be explored
-- as a small analytical dataset, revealing patterns in purchasing
-- behavior, pricing, and reading habits.
