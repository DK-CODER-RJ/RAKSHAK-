CREATE TABLE contacts (id UUID PRIMARY KEY, user_id UUID REFERENCES users(id), name VARCHAR(255), phone VARCHAR(20), is_primary BOOLEAN DEFAULT false, relationship VARCHAR(100));
