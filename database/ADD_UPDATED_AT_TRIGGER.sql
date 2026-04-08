-- Enable trigger to automatically update the updated_at column in bins table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trg_bins_updated_at ON bins;

CREATE TRIGGER trg_bins_updated_at
BEFORE UPDATE ON bins
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
