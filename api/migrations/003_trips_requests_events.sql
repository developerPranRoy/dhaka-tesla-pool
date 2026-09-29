-- Trips (the pool), passenger ride requests, and an append-only audit log.

CREATE TABLE trips (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id   uuid NOT NULL REFERENCES vehicles (id),
  pickup_zone  text NOT NULL REFERENCES zones (name),
  corridor     text NOT NULL,
  status       text NOT NULL DEFAULT 'OPEN'
               CHECK (status IN ('OPEN', 'DRIVER_ARRIVED', 'STARTED', 'COMPLETED', 'CANCELLED')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  started_at   timestamptz,
  completed_at timestamptz
);

-- A Tesla can run only one active trip at a time.
CREATE UNIQUE INDEX trips_one_active_per_vehicle
  ON trips (vehicle_id)
  WHERE status IN ('OPEN', 'DRIVER_ARRIVED', 'STARTED');

CREATE INDEX trips_vehicle_history ON trips (vehicle_id, created_at DESC);

CREATE TABLE ride_requests (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id     uuid NOT NULL REFERENCES users (id),
  trip_id          uuid REFERENCES trips (id),
  pickup_zone      text NOT NULL REFERENCES zones (name),
  destination_zone text NOT NULL REFERENCES zones (name),
  seats            integer NOT NULL CHECK (seats > 0),
  fare_paisa       integer NOT NULL CHECK (fare_paisa >= 0),
  fare_frozen      boolean NOT NULL DEFAULT false,
  status           text NOT NULL DEFAULT 'REQUESTED'
                   CHECK (status IN ('REQUESTED', 'MATCHED', 'STARTED', 'COMPLETED', 'CANCELLED')),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ride_requests_distinct_zones CHECK (pickup_zone <> destination_zone),
  -- REQUESTED means not yet on a trip; matched/started/completed must be on one.
  CONSTRAINT ride_requests_requested_has_no_trip CHECK (status <> 'REQUESTED' OR trip_id IS NULL),
  CONSTRAINT ride_requests_assigned_has_trip
    CHECK (status NOT IN ('MATCHED', 'STARTED', 'COMPLETED') OR trip_id IS NOT NULL)
);

-- A passenger can have only one active request at a time.
CREATE UNIQUE INDEX ride_requests_one_active_per_passenger
  ON ride_requests (passenger_id)
  WHERE status IN ('REQUESTED', 'MATCHED', 'STARTED');

-- Driver's "available requests" query.
CREATE INDEX ride_requests_open_by_pickup
  ON ride_requests (pickup_zone, created_at)
  WHERE status = 'REQUESTED';

-- Seat sums per trip.
CREATE INDEX ride_requests_trip ON ride_requests (trip_id);

-- Passenger history.
CREATE INDEX ride_requests_passenger_history ON ride_requests (passenger_id, created_at DESC);

-- Append-only history: every state change writes a row in the same transaction.
CREATE TABLE ride_events (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  trip_id     uuid REFERENCES trips (id),
  request_id  uuid REFERENCES ride_requests (id),
  actor_id    uuid NOT NULL REFERENCES users (id),
  event_type  text NOT NULL,
  from_status text,
  to_status   text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (trip_id IS NOT NULL OR request_id IS NOT NULL)
);

CREATE INDEX ride_events_trip ON ride_events (trip_id, created_at);
CREATE INDEX ride_events_request ON ride_events (request_id, created_at);
