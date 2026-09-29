-- Users (passengers and drivers) and their Teslas.

CREATE TABLE users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL CHECK (length(trim(name)) > 0),
  email         text NOT NULL,
  password_hash text NOT NULL,
  role          text NOT NULL CHECK (role IN ('PASSENGER', 'DRIVER')),
  is_online     boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  -- only drivers can be online
  CONSTRAINT users_online_only_drivers CHECK (role = 'DRIVER' OR is_online = false)
);

-- Case-insensitive unique email
CREATE UNIQUE INDEX users_email_lower_key ON users (lower(email));

CREATE TABLE vehicles (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL UNIQUE REFERENCES users (id),
  name      text NOT NULL CHECK (length(trim(name)) > 0),
  capacity  integer NOT NULL CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);
