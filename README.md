## Smart Mapping with Spatial Data Analytics

### Revolutionizing Infrastructure Visualization in Ireland with QGIS

---

### **Project Overview:**

This project leverages the power of **QGIS** and **PostGIS** to perform advanced spatial analysis, mapping key infrastructure amenities across Ireland. By exploring the spatial relationships between **restaurants**, **hotels**, and **public transport**, the project identifies both well-serviced areas and locations that could benefit from enhanced connectivity and infrastructure planning.

---

### **Data Sources:**

* **OpenStreetMap (OSM)** for spatial data on amenities and infrastructure.
* **Open Data Ireland** for regional boundaries and infrastructure layers.
* **GeoJSON files** for custom mapping and visualization.

---

### **Methodology:**

1. **Data Collection:**

   * Sourced data from OSM and Open Data portals.
   * Utilized GeoJSON for custom overlays.

2. **Data Preparation and Cleaning:**

   * Imported datasets into **PostGIS** for spatial querying.
   * Cleaned and normalized data to ensure consistency.

3. **Spatial Queries and Analysis:**

   * Conducted spatial joins to identify key amenities within specified radii:

     * Restaurants within **500m** of key locations.
     * Hotels within **1km** of key locations.
     * Public transport stops within **300m**.

4. **Visualization with QGIS:**

   * Mapped results with color-coded markers for clarity.
   * Generated heatmaps and layer overlays to highlight underserved regions.

---

### **Key Findings:**

* Discovered optimal zones for hospitality and public transport enhancements.
* Mapped regions with dense infrastructure and areas with expansion potential.
* Highlighted critical gaps where development can drive economic growth.

---

### **How to Run the Project:**

1. Clone this repository:

   ```
   git clone https://github.com/yourusername/SmartMapping-Ireland.git
   ```
2. Import datasets into **PostGIS** using:

   ```
   psql -U username -d database_name -f data_dump.sql
   ```
3. Run SQL queries located in the `/queries` folder to extract insights.
4. Open the QGIS project file to view spatial visualizations.

---

### **Future Enhancements:**

* Integrate **Real-Time Data Streams** for live updates on infrastructure changes.
* Expand analysis to include **traffic congestion** and **population density**.
* Enhance **predictive modeling** for urban planning and infrastructure optimization.

---

### **License:**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

### **Contact:**

Feel free to reach out for collaborations or discussions on spatial analytics and urban planning.

---

**Author:** Sharanya Santosh
**Module:** CS621 - Geospatial Story Project
