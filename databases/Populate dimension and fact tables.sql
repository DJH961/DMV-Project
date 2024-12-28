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
                          price_dkk, latitude, longitude)
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
    longitude
FROM staging_listings;

-- Populate Reviews Dimension
INSERT INTO dim_reviews (review_id, listing_id, reviewer_id, reviewer_name, review_date, comments)
SELECT DISTINCT
    id AS review_id,
    listing_id,
    reviewer_id,
    reviewer_name,
    date::DATE AS review_date,
    comments
FROM staging_reviews
WHERE listing_id IN (SELECT listing_id FROM dim_listings);


-- Populate Bookings Fact Table
INSERT INTO fact_bookings (listing_id, date, available, price, adjusted_price, minimum_nights, maximum_nights)
SELECT DISTINCT
    listing_id,
    date::DATE,
    CASE WHEN available = 't' THEN TRUE ELSE FALSE END AS available,
    price::NUMERIC,
    adjusted_price::NUMERIC,
    minimum_nights,
    maximum_nights
FROM staging_calendar;

-- Populate Success Fact Table
INSERT INTO fact_success (listing_id, host_id, success_score, reviews_count, average_rating)
SELECT DISTINCT
    l.listing_id,
    l.host_id,
    (l.number_of_reviews * 0.5 + l.review_scores_rating * 0.3) AS success_score,
    l.number_of_reviews,
    l.review_scores_rating
FROM staging_listings l;
