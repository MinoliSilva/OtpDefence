-- OTP Spoofing Defense App Schema

-- Drop existing tables if re-running
DROP TABLE IF EXISTS analytics;
DROP TABLE IF EXISTS risk_rules;
DROP TABLE IF EXISTS scam_number_hashes;
DROP TABLE IF EXISTS trusted_senders;

-- 1. Trusted Senders
CREATE TABLE trusted_senders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id TEXT UNIQUE NOT NULL, -- e.g., 'BOC', 'SAMPATH', 'HNB'
    trust_score INTEGER DEFAULT 100,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Scam Number Hashes
-- Use SHA-256 hashes instead of raw numbers to protect privacy
CREATE TABLE scam_number_hashes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hash TEXT UNIQUE NOT NULL,
    report_count INTEGER DEFAULT 1,
    last_reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Risk Rules
CREATE TABLE risk_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_type TEXT NOT NULL, -- e.g., 'REGEX', 'KEYWORD'
    pattern TEXT NOT NULL,
    weight INTEGER NOT NULL, -- Impact on risk score
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Analytics
-- Only non-PII, anonymized data is stored here
CREATE TABLE analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id_hash TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    risk_score INTEGER NOT NULL,
    classification TEXT NOT NULL, -- 'Safe', 'Warning', 'High Risk'
    matched_rules JSONB, -- Array of rule IDs that fired
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Default Data (Sri Lanka Context)
INSERT INTO trusted_senders (sender_id) VALUES 
('ComBank'), ('SAMPATH'), ('BOC'), ('HNB'), ('NTB'), ('DFCC'), ('DIALOG'), ('MOBITEL');

INSERT INTO risk_rules (rule_type, pattern, weight, description) VALUES 
('KEYWORD', 'urgent', 15, 'Urgency keyword detected'),
('KEYWORD', 'suspend', 20, 'Suspension threat detected'),
('KEYWORD', 'login', 10, 'Login request pattern'),
('REGEX', 'https?:\/\/[^\s]+', 30, 'URL present in message'),
('KEYWORD', 'ලොගින්', 25, 'Sinhala "login" keyword'),
('KEYWORD', 'ගිණුම අත්හිටුවා ඇත', 40, 'Sinhala "Account suspended" phrase'),
('KEYWORD', 'கணக்கு முடக்கப்பட்டது', 40, 'Tamil "Account suspended" phrase');
