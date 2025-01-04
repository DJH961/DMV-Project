-- Create Dimension Tables
CREATE TABLE dim_hosts (
    host_id BIGINT PRIMARY KEY,
    host_name TEXT,
    host_since DATE,
    host_location TEXT,
    host_response_time TEXT,
    host_response_rate TEXT,
    host_acceptance_rate TEXT,
    host_is_superhost BOOLEAN,
    host_total_listings_count INT
);

CREATE TABLE dim_listings (
    listing_id BIGINT PRIMARY KEY,
    name TEXT,
    neighbourhood TEXT,
    neighbourhood_cleansed TEXT,
    property_type TEXT,
    room_type TEXT,
    accommodates INT,
    bathrooms_text TEXT,
    bedrooms INT,
    beds INT,
    amenities TEXT,
    price_dkk NUMERIC,
    latitude NUMERIC,
    longitude NUMERIC,
    num_amenities INT
);

CREATE TABLE dim_reviews (
    review_id BIGINT PRIMARY KEY,
    listing_id BIGINT REFERENCES dim_listings(listing_id),
    reviewer_id BIGINT,
    reviewer_name TEXT,
    review_date DATE,
    comments TEXT
);

 DROP TABLE IF EXISTS fact_bookings;

-- Create Fact Tables
CREATE TABLE fact_bookings (
    booking_id SERIAL PRIMARY KEY,  -- Auto-incrementing unique identifier for each booking
    listing_id BIGINT REFERENCES dim_listings(listing_id),        
    booked_from DATE NOT NULL,     
    booked_to DATE NOT NULL,        
    price NUMERIC, 
    days_booked INT,  
    potential_revenue NUMERIC
);

DROP TABLE IF EXISTS fact_success;

CREATE TABLE fact_success (
    success_id SERIAL PRIMARY KEY,
    listing_id BIGINT REFERENCES dim_listings(listing_id),
    host_id BIGINT REFERENCES dim_hosts(host_id),
    success_score NUMERIC,
    reviews_count INT,
    average_rating NUMERIC,
    price_dkk NUMERIC
);
