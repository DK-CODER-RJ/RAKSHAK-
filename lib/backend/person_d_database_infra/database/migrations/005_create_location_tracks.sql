CREATE TABLE location_tracks (id UUID PRIMARY KEY, sos_event_id UUID, latitude DECIMAL, longitude DECIMAL, accuracy DECIMAL, timestamp TIMESTAMP DEFAULT NOW());
