-- Predefined Dhaka zones, corridors and a symmetric distance lookup.
-- Distances are in metres. Banani-Mohakhali (2500) and Banani-Gulshan 1 (3500)
-- are the fixed demo values; the rest are illustrative approximations.

CREATE TABLE zones (
  name     text PRIMARY KEY,
  corridor text NOT NULL
);

INSERT INTO zones (name, corridor) VALUES
  ('Banani',      'Banani'),
  ('Mohakhali',   'North-East'),
  ('Gulshan 1',   'North-East'),
  ('Bashundhara', 'North-East'),
  ('Uttara',      'North'),
  ('Farmgate',    'Central'),
  ('Dhanmondi',   'Central'),
  ('Mirpur',      'West');

-- One row per unordered pair; zone_a < zone_b. Look up with LEAST/GREATEST.
CREATE TABLE zone_distances (
  zone_a text NOT NULL REFERENCES zones (name),
  zone_b text NOT NULL REFERENCES zones (name),
  meters integer NOT NULL CHECK (meters > 0),
  PRIMARY KEY (zone_a, zone_b),
  CHECK (zone_a < zone_b)
);

INSERT INTO zone_distances (zone_a, zone_b, meters)
SELECT LEAST(a, b), GREATEST(a, b), m
FROM (VALUES
  ('Banani', 'Mohakhali',   2500),
  ('Banani', 'Gulshan 1',   3500),
  ('Banani', 'Bashundhara', 6500),
  ('Banani', 'Farmgate',    5000),
  ('Banani', 'Dhanmondi',   8000),
  ('Banani', 'Mirpur',      8500),
  ('Banani', 'Uttara',     10500),
  ('Bashundhara', 'Dhanmondi', 11000),
  ('Bashundhara', 'Farmgate',   8000),
  ('Bashundhara', 'Gulshan 1',  4500),
  ('Bashundhara', 'Mirpur',    12000),
  ('Bashundhara', 'Mohakhali',  6000),
  ('Bashundhara', 'Uttara',     8000),
  ('Dhanmondi', 'Farmgate',  3500),
  ('Dhanmondi', 'Gulshan 1', 9500),
  ('Dhanmondi', 'Mirpur',    8500),
  ('Dhanmondi', 'Mohakhali', 7500),
  ('Dhanmondi', 'Uttara',   15000),
  ('Farmgate', 'Gulshan 1',  6000),
  ('Farmgate', 'Mirpur',     6500),
  ('Farmgate', 'Mohakhali',  3500),
  ('Farmgate', 'Uttara',    12000),
  ('Gulshan 1', 'Mirpur',   11000),
  ('Gulshan 1', 'Mohakhali', 3000),
  ('Gulshan 1', 'Uttara',    8000),
  ('Mirpur', 'Mohakhali',    7500),
  ('Mirpur', 'Uttara',      13000),
  ('Mohakhali', 'Uttara',    9500)
) AS v (a, b, m);
