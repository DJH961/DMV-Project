
-- DROP TABLE IF EXISTS public.staging_calendar;

CREATE TABLE IF NOT EXISTS public.staging_calendar
(
    listing_id bigint,
    date date,
    available boolean,
    price double precision,
    adjusted_price double precision,
    minimum_nights double precision,
    maximum_nights double precision
)

-- DROP TABLE IF EXISTS public.staging_listings;

CREATE TABLE IF NOT EXISTS public.staging_listings
(
    listing_id bigint NOT NULL,
    listing_url text COLLATE pg_catalog."default",
    scrape_id bigint,
    last_scraped date,
    source text COLLATE pg_catalog."default",
    name text COLLATE pg_catalog."default",
    picture_url text COLLATE pg_catalog."default",
    host_id bigint,
    host_url text COLLATE pg_catalog."default",
    host_name text COLLATE pg_catalog."default",
    host_since date,
    host_location text COLLATE pg_catalog."default",
    host_response_time text COLLATE pg_catalog."default",
    host_response_rate double precision,
    host_acceptance_rate double precision,
    host_is_superhost boolean,
    host_thumbnail_url text COLLATE pg_catalog."default",
    host_picture_url text COLLATE pg_catalog."default",
    host_neighbourhood text COLLATE pg_catalog."default",
    host_listings_count double precision,
    host_total_listings_count double precision,
    host_verifications text COLLATE pg_catalog."default",
    host_has_profile_pic boolean,
    host_identity_verified boolean,
    neighbourhood text COLLATE pg_catalog."default",
    neighbourhood_cleansed text COLLATE pg_catalog."default",
    latitude double precision,
    longitude double precision,
    property_type text COLLATE pg_catalog."default",
    room_type text COLLATE pg_catalog."default",
    accommodates integer,
    bathrooms_text text COLLATE pg_catalog."default",
    bedrooms double precision,
    beds double precision,
    amenities text COLLATE pg_catalog."default",
    price_dkk double precision,
    minimum_nights integer,
    maximum_nights integer,
    minimum_minimum_nights integer,
    maximum_minimum_nights integer,
    minimum_maximum_nights integer,
    maximum_maximum_nights integer,
    minimum_nights_avg_ntm double precision,
    maximum_nights_avg_ntm double precision,
    has_availability boolean,
    availability_30 integer,
    availability_60 integer,
    availability_90 integer,
    availability_365 integer,
    calendar_last_scraped date,
    number_of_reviews integer,
    number_of_reviews_ltm integer,
    number_of_reviews_l30d integer,
    first_review date,
    last_review date,
    review_scores_rating double precision,
    review_scores_accuracy double precision,
    review_scores_cleanliness double precision,
    review_scores_checkin double precision,
    review_scores_communication double precision,
    review_scores_location double precision,
    review_scores_value double precision,
    instant_bookable boolean,
    calculated_host_listings_count integer,
    calculated_host_listings_count_entire_homes integer,
    calculated_host_listings_count_private_rooms integer,
    calculated_host_listings_count_shared_rooms integer,
    reviews_per_month double precision,
    number_of_bathrooms double precision,
    type_of_bathroom text COLLATE pg_catalog."default",
    description_format text COLLATE pg_catalog."default",
    neighborhood_overview_format text COLLATE pg_catalog."default",
    host_about_format text COLLATE pg_catalog."default",
    num_amenities integer,
    label_en text COLLATE pg_catalog."default",
    CONSTRAINT staging_listings_pkey PRIMARY KEY (listing_id)
)

-- DROP TABLE IF EXISTS public.staging_reviews;

CREATE TABLE IF NOT EXISTS public.staging_reviews
(
    listing_id bigint,
    guest_id bigint NOT NULL,
    review_date date,
    reviewer_id bigint,
    reviewer_name text COLLATE pg_catalog."default",
    comments text COLLATE pg_catalog."default",
    CONSTRAINT staging_reviews_pkey PRIMARY KEY (guest_id)
)

