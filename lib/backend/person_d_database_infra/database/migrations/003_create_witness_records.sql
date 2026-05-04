CREATE TABLE witness_records (id UUID PRIMARY KEY, user_id UUID REFERENCES users(id), sos_event_id UUID, video_url TEXT, audio_url TEXT, created_at TIMESTAMP DEFAULT NOW());
