-- Truncate tables before populating
TRUNCATE TABLE dim_hosts CASCADE;
TRUNCATE TABLE dim_listings CASCADE;
TRUNCATE TABLE dim_reviews;
TRUNCATE TABLE fact_bookings;
TRUNCATE TABLE fact_success;

-- Populate Hosts Dimension
INSERT INTO dim_hosts (host_id, host_name, host_since, host_location, host_response_time, 
                       host_response_rate, host_acceptance_rate, host_is_superhost, 
                       host_total_listings_count)
SELECT DISTINCT
    host_id,
    host_name,
    host_since::DATE,
    host_location,
    host_response_time,
    host_response_rate,
    host_acceptance_rate,
    CASE WHEN host_is_superhost = 't' THEN TRUE ELSE FALSE END,
    host_total_listings_count
FROM staging_listings;

-- Populate Listings Dimension
INSERT INTO dim_listings (listing_id, name, neighbourhood, neighbourhood_cleansed, property_type, 
                          room_type, accommodates, bathrooms_text, bedrooms, beds, amenities, 
                          price_dkk, latitude, longitude, num_amenities, municipality)
SELECT DISTINCT
    listing_id,
    name,
    neighbourhood,
    neighbourhood_cleansed,
    property_type,
    room_type,
    accommodates,
    bathrooms_text,
    bedrooms,
    beds,
    amenities,
    price_dkk::NUMERIC,
    latitude,
    longitude,
    num_amenities,
    label_en
FROM staging_listings;

-- Populate Reviews Dimension
INSERT INTO dim_reviews (review_id, listing_id, reviewer_id, reviewer_name, review_date, comments)
SELECT DISTINCT
    guest_id AS review_id,
    listing_id,
    reviewer_id,
    reviewer_name,
    review_date::DATE AS review_date,
    comments
FROM staging_reviews
WHERE listing_id IN (SELECT listing_id FROM dim_listings);


-- Populate Bookings Fact Table
WITH sorted_data AS (
    SELECT
        listing_id,
        date,
        price,
        -- Calculate the difference in days from the previous date within the same listing_id as a numeric value
        (date - LAG(date) OVER (PARTITION BY listing_id ORDER BY date)) AS date_diff
    FROM staging_calendar
    WHERE available = FALSE
),

grouped_data AS (
    SELECT
        listing_id,
        date,
        price,
        -- Create a group identifier by checking gaps in dates
        SUM(CASE 
            WHEN date_diff IS NULL OR date_diff > 1 THEN 1 
            ELSE 0 
        END) OVER (PARTITION BY listing_id ORDER BY date) AS group_id
    FROM sorted_data
),

aggregated_bookings AS (
    SELECT
        listing_id,
        group_id,
        MIN(date) AS booked_from,  -- First date in the group
        MAX(date) AS booked_to,    -- Last date in the group
        MAX(price) AS price        -- Price for the listing
    FROM grouped_data
    GROUP BY listing_id, group_id
),

final_bookings AS (
    SELECT
        listing_id,
        group_id,
        booked_from,
        booked_to,
        price,
        -- Calculate the number of days booked
        (AGE(booked_to, booked_from) + INTERVAL '1 day') AS days_booked,
        -- Calculate potential revenue
        price * (EXTRACT(DAY FROM AGE(booked_to, booked_from)) + 1) AS potential_revenue
    FROM aggregated_bookings
)
INSERT INTO fact_bookings (listing_id, booked_from, booked_to, price, days_booked, potential_revenue)
SELECT
    listing_id,
    booked_from,
    booked_to,
    price,
    EXTRACT(DAY FROM days_booked)::INT AS days_booked,
    potential_revenue
FROM final_bookings;





-- Populate Success Fact Table
WITH booked_days as 
(SELECT COUNT (DISTINCT s.date) as days_booked, s.listing_id
FROM staging_calendar s
WHERE s.available=FALSE GROUP BY s.listing_id),
fact_table as (
SELECT DISTINCT
    l.listing_id,
    l.host_id,
    l.number_of_reviews,
    l.review_scores_rating,
    COALESCE(booked_days.days_booked, 0) AS days_booked,
    l.price_dkk
FROM staging_listings l
LEFT JOIN booked_days ON booked_days.listing_id=l.listing_id),

stats AS (
    SELECT
		AVG(number_of_reviews) AS mean_reviews,
        STDDEV(number_of_reviews) AS stddev_reviews,
		MAX(number_of_reviews) as max_reviews,
		MIN(review_scores_rating) as min_rating,
		MAX(review_scores_rating) as max_rating,
        AVG(price_dkk) AS mean_price,
        STDDEV(price_dkk) AS stddev_price
    FROM fact_table
),
normalized_data AS (
    SELECT
        f.listing_id,
    	f.host_id,
		f.number_of_reviews,
    	f.review_scores_rating,
    	f.days_booked,
    	f.price_dkk,
		--Log Normalization for Reviews and Ratings to between 0 and 1
		LOG(f.review_scores_rating -stats.min_rating + 1) / LOG(stats.max_rating -stats.min_rating + 1) as normalized_rating,
		--1 / (1 + EXP(-(f.number_of_reviews - stats.mean_reviews) / stats.stddev_reviews)) as normalized_reviews,
		LOG(f.number_of_reviews  + 1) / LOG(stats.max_reviews + 1) as normalized_reviews,
		f.days_booked/365.0 as booked_percentage,
		--Price normalized with z-score and sigmoid
		1 / (1 + EXP(-(f.price_dkk - stats.mean_price) / stats.stddev_price)) as normalized_price
    FROM fact_table f, stats
)
INSERT INTO fact_success (listing_id, host_id, reviews_count, average_rating, days_booked, price_dkk, booked_percentage,performance_score, quality_score)
SELECT
        listing_id,
    	host_id,
		number_of_reviews,
    	review_scores_rating,
    	days_booked,
    	price_dkk,
		booked_percentage,
		ROUND((normalized_rating+normalized_reviews+booked_percentage+normalized_price)*25) AS performance_score,
		ROUND((normalized_rating+normalized_reviews+booked_percentage)/0.03) AS quality_score
    FROM normalized_data
