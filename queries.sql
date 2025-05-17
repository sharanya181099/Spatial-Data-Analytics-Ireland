--1.  No. of residential buildings within each neighborhood to find where the residential properties are densily located.
SELECT b.name AS neighborhood_name,
COUNT(h.ogc_fid) AS total_homes
FROM galway_boundary b
LEFT JOIN galway_homes h
ON ST_Within(h.hgeom, b.bgeom)
GROUP BY b.name
ORDER BY total_homes DESC;


--2. Homes Accessible to Each Amenity Type
WITH 
-- Creating buffers for each amenity
park_buffers AS (
 	SELECT ST_Buffer(pgeom, 200) AS buffer_geom FROM galway_parks),
transport_buffers AS (
    SELECT ST_Buffer(tgeom, 200) AS buffer_geom FROM galway_transportstop),
sch_buffers AS (
    SELECT ST_Buffer(schgeom, 200) AS buffer_geom, amenity FROM galway_shc),
store_buffers AS (SELECT ST_Buffer(sgeom, 200) AS buffer_geom FROM galway_stores)
SELECT 
    b.name AS neighborhood_name,
    COUNT(h.ogc_fid) AS total_homes,
    COUNT(h.ogc_fid) FILTER (WHERE EXISTS (
        SELECT 1 FROM park_buffers p WHERE ST_Within(h.hgeom, p.buffer_geom)
    )) AS homes_near_parks,
    COUNT(h.ogc_fid) FILTER (WHERE EXISTS (
        SELECT 1 FROM transport_buffers t WHERE ST_Within(h.hgeom, t.buffer_geom)
    )) AS homes_near_transport,
    COUNT(h.ogc_fid) FILTER (WHERE EXISTS (
        SELECT 1 FROM sch_buffers s WHERE s.amenity = 'school' AND ST_Within(h.hgeom, s.buffer_geom)
    )) AS homes_near_schools,
    COUNT(h.ogc_fid) FILTER (WHERE EXISTS (
        SELECT 1 FROM sch_buffers s WHERE s.amenity IN ('hospital', 'clinic') AND ST_Within(h.hgeom, s.buffer_geom)
    )) AS homes_near_healthcare,
    COUNT(h.ogc_fid) FILTER (WHERE EXISTS (
        SELECT 1 FROM store_buffers st WHERE ST_Within(h.hgeom, st.buffer_geom)
    )) AS homes_near_stores
FROM galway_boundary b LEFT JOIN galway_homes h
ON ST_Within(h.hgeom, b.bgeom) GROUP BY b.name 
ORDER BY homes_near_parks DESC, homes_near_transport DESC, homes_near_schools DESC, homes_near_healthcare DESC, homes_near_stores DESC;



--3. Total Accessible Amenities per Neighborhood
WITH 
pedestrian_accessible_zones AS (
    SELECT buffer_geom, 'Park' AS type FROM (SELECT ST_Buffer(pgeom, 200) AS buffer_geom FROM galway_parks) p
    UNION ALL
    SELECT buffer_geom, 'Transport' AS type FROM (SELECT ST_Buffer(tgeom, 200) AS buffer_geom FROM galway_transportstop) t
    UNION ALL
    SELECT buffer_geom, amenity AS type FROM (SELECT ST_Buffer(schgeom, 200) AS buffer_geom, amenity FROM galway_shc) s
    UNION ALL
    SELECT buffer_geom, 'Store' AS type FROM (SELECT ST_Buffer(sgeom, 200) AS buffer_geom FROM galway_stores) st
)
SELECT 
    b.name AS neighborhood_name,
    COUNT(p.type) AS total_amenities, -- Total count of all amenities
    COUNT(DISTINCT p.type) AS unique_amenity_types -- Unique count of amenity types
FROM galway_boundary b
LEFT JOIN pedestrian_accessible_zones p 
    ON ST_DWithin(b.bgeom, p.buffer_geom, 200) 
GROUP BY b.name 
ORDER BY total_amenities DESC;


--View for total amenities 
CREATE VIEW galway_boundary_with_amenities AS
WITH 
pedestrian_accessible_zones AS (
    SELECT buffer_geom, 'Park' AS type 
    FROM (SELECT ST_Buffer(pgeom, 200) AS buffer_geom FROM galway_parks) p
    UNION ALL
    SELECT buffer_geom, 'Transport' AS type 
    FROM (SELECT ST_Buffer(tgeom, 200) AS buffer_geom FROM galway_transportstop) t
    UNION ALL
    SELECT buffer_geom, 'School' AS type 
    FROM (SELECT ST_Buffer(schgeom, 200) AS buffer_geom FROM galway_shc) s
    UNION ALL
    SELECT buffer_geom, 'Store' AS type 
    FROM (SELECT ST_Buffer(sgeom, 200) AS buffer_geom FROM galway_stores) st
)
SELECT 
    b.name AS neighborhood_name,
    b.bgeom AS boundary_geom,
    COUNT(p.type) AS total_amenities
FROM galway_boundary b
LEFT JOIN pedestrian_accessible_zones p 
    ON b.bgeom <-> p.buffer_geom <= 200
GROUP BY b.name, b.bgeom
ORDER BY total_amenities DESC;


--4. Accessibility Ratio
WITH 
-- Buffers for each amenity
park_buffers AS (SELECT ST_Union(ST_Buffer(pgeom, 200)) AS buffer_geom FROM galway_parks),
transport_buffers AS (SELECT ST_Union(ST_Buffer(tgeom, 200)) AS buffer_geom FROM galway_transportstop),
sch_buffers AS (SELECT ST_Union(ST_Buffer(schgeom, 200)) AS buffer_geom FROM galway_shc WHERE amenity = 'school'),
healthcare_buffers AS (SELECT ST_Union(ST_Buffer(schgeom, 200)) AS buffer_geom FROM galway_shc WHERE amenity IN ('hospital', 'clinic')),
store_buffers AS (SELECT ST_Union(ST_Buffer(sgeom, 200)) AS buffer_geom FROM galway_stores)
SELECT b.name AS neighborhood_name,
    -- Overall Accessibility Ratio
    ROUND(CAST(ST_Area(ST_Intersection(b.bgeom, (
        SELECT ST_Union(buffer_geom) 
        FROM (SELECT * FROM park_buffers UNION ALL 
              SELECT * FROM transport_buffers UNION ALL 
              SELECT * FROM sch_buffers UNION ALL 
              SELECT * FROM healthcare_buffers UNION ALL 
              SELECT * FROM store_buffers) AS combined_buffers
    ))) / 5000000 * 100 AS numeric), 2) AS overall_accessibility_ratio,
 -- Parks Accessibility Ratio
ROUND(CAST(ST_Area(ST_Intersection(b.bgeom, (SELECT buffer_geom FROM park_buffers))) / ST_Area(b.bgeom) * 100 AS numeric), 2) AS parks_ratio,
-- Transport Stops Accessibility Ratio
ROUND(CAST(ST_Area(ST_Intersection(b.bgeom, (SELECT buffer_geom FROM transport_buffers))) / ST_Area(b.bgeom) * 100 AS numeric), 2) AS transport_ratio,
-- Schools Accessibility Ratio
ROUND(CAST(ST_Area(ST_Intersection(b.bgeom, (SELECT buffer_geom FROM sch_buffers))) / ST_Area(b.bgeom) * 100 AS numeric), 2) AS schools_ratio,
-- Healthcare Accessibility Ratio
ROUND(CAST(ST_Area(ST_Intersection(b.bgeom, (SELECT buffer_geom FROM healthcare_buffers))) / ST_Area(b.bgeom) * 100 AS numeric), 2) AS healthcare_ratio,
-- Stores Accessibility Ratio
ROUND(CAST(ST_Area(ST_Intersection(b.bgeom, (SELECT buffer_geom FROM store_buffers))) / ST_Area(b.bgeom) * 100 AS numeric), 2) AS stores_ratio
FROM galway_boundary b
ORDER BY overall_accessibility_ratio DESC;


--5. Identify Underserved Neighborhoods
WITH 
pedestrian_accessible_zones AS (
    SELECT buffer_geom, 'Park' AS type FROM (SELECT ST_Buffer(pgeom, 200) AS buffer_geom FROM galway_parks) p
    UNION ALL
    SELECT buffer_geom, 'Transport' AS type FROM (SELECT ST_Buffer(tgeom, 200) AS buffer_geom FROM galway_transportstop) t
    UNION ALL
    SELECT buffer_geom, amenity AS type FROM (SELECT ST_Buffer(schgeom, 200) AS buffer_geom, amenity FROM galway_shc) s
    UNION ALL
    SELECT buffer_geom, 'Store' AS type FROM (SELECT ST_Buffer(sgeom, 200) AS buffer_geom FROM galway_stores) st
)
SELECT 
    b.name AS neighborhood_name,
    COUNT(DISTINCT p.type) AS total_accessible_amenities
FROM galway_boundary b
LEFT JOIN pedestrian_accessible_zones p ON ST_Intersects(b.bgeom, p.buffer_geom)
GROUP BY b.name
HAVING COUNT(DISTINCT p.type) = 0


-- View for underserved neighborhood 
WITH 
pedestrian_accessible_zones AS (
    SELECT buffer_geom, 'Park' AS type FROM (SELECT ST_Buffer(pgeom, 200) AS buffer_geom FROM galway_parks) p
    UNION ALL
    SELECT buffer_geom, 'Transport' AS type FROM (SELECT ST_Buffer(tgeom, 200) AS buffer_geom FROM galway_transportstop) t
    UNION ALL
    SELECT buffer_geom, amenity AS type FROM (SELECT ST_Buffer(schgeom, 200) AS buffer_geom, amenity FROM galway_shc) s
    UNION ALL
    SELECT buffer_geom, 'Store' AS type FROM (SELECT ST_Buffer(sgeom, 200) AS buffer_geom FROM galway_stores) st
)
SELECT 
    b.name AS neighborhood_name,
    b.bgeom AS geometry,
    COUNT(DISTINCT p.type) AS total_accessible_amenities
FROM galway_boundary b
LEFT JOIN pedestrian_accessible_zones p ON ST_Intersects(b.bgeom, p.buffer_geom)
GROUP BY b.name, b.bgeom
HAVING COUNT(DISTINCT p.type) = 0
ORDER BY total_accessible_amenities ASC;



-- 6. Walkability index 
WITH 
-- Create buffers for each amenity type
park_buffers AS (SELECT ogc_fid, ST_Buffer(pgeom, 200) AS buffer_geom FROM galway_parks),
transport_buffers AS (SELECT ogc_fid, ST_Buffer(tgeom, 200) AS buffer_geom FROM galway_transportstop),
sch_buffers AS (SELECT ogc_fid, amenity, ST_Buffer(schgeom, 200) AS buffer_geom FROM galway_shc),
store_buffers AS (SELECT ogc_fid, ST_Buffer(sgeom, 200) AS buffer_geom FROM galway_stores),
region_accessibility AS (
    SELECT 
        b.name AS region_name,
        COUNT(DISTINCT p.ogc_fid) FILTER (WHERE ST_Intersects(b.bgeom, p.buffer_geom)) AS park_count,
        COUNT(DISTINCT t.ogc_fid) FILTER (WHERE ST_Intersects(b.bgeom, t.buffer_geom)) AS transport_count,
        COUNT(DISTINCT s.ogc_fid) FILTER (WHERE s.amenity = 'school' AND ST_Intersects(b.bgeom, s.buffer_geom)) AS school_count,
        COUNT(DISTINCT s.ogc_fid) FILTER (WHERE s.amenity IN ('hospital', 'clinic') AND ST_Intersects(b.bgeom, s.buffer_geom)) AS healthcare_count,
        COUNT(DISTINCT st.ogc_fid) FILTER (WHERE ST_Intersects(b.bgeom, st.buffer_geom)) AS store_count
    FROM 
        galway_boundary b LEFT JOIN 
		park_buffers p ON ST_Intersects(b.bgeom, p.buffer_geom)
    LEFT JOIN 
        transport_buffers t ON ST_Intersects(b.bgeom, t.buffer_geom)
    LEFT JOIN 
        sch_buffers s ON ST_Intersects(b.bgeom, s.buffer_geom)
    LEFT JOIN 
        store_buffers st ON ST_Intersects(b.bgeom, st.buffer_geom)
    GROUP BY 
        b.name
)
SELECT region_name,
    -- Normalizing and assigning weights to each amenity
    ROUND((park_count * 0.3 + transport_count * 0.25 + school_count * 0.2 + healthcare_count * 0.15 + store_count * 0.1), 2) AS walkability_index
FROM region_accessibility
ORDER BY walkability_index DESC;

