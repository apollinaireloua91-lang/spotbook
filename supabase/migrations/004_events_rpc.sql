-- Increment sold_count on ticket_types after purchase
CREATE OR REPLACE FUNCTION increment_sold_count(p_ticket_type_id UUID, p_quantity INT)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE ticket_types
    SET sold_count = sold_count + p_quantity
    WHERE id = p_ticket_type_id;
END;
$$;
