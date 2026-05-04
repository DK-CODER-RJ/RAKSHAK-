CREATE TABLE sos_events (id UUID PRIMARY KEY, user_id UUID REFERENCES users(id), status VARCHAR(50), latitude DECIMAL, longitude DECIMAL, created_at TIMESTAMP DEFAULT NOW());
