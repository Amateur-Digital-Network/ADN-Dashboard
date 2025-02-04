<div class="container">
    <p id="stats"></p>
    <?php
    try {
        $db = new SQLite3('db/dashboard.db');
        // Query for peers with ID > 7 digits and N/A frequencies
        $query = "SELECT * FROM masters_table 
                 WHERE peer_id > 999999 
                 AND rx_freq != 'N/A' 
                 AND tx_freq != 'N/A'";
        $result = $db->query($query);
        
        $markers = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            // Validate coordinates and exclude 0 values
            if (!empty($row['latitude']) && 
                !empty($row['longitude']) &&
                is_numeric($row['latitude']) && 
                is_numeric($row['longitude']) &&
                (float)$row['latitude'] != 0 &&   // Exclude 0 latitude
                (float)$row['longitude'] != 0) {  // Exclude 0 longitude
                $markers[] = $row;
            }
        }
        $db->close();

        if (!empty($markers)) {
            echo '<div class="row justify-content-center">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-body p-0">
                                <div id="map" style="height: 600px; width: 100%;"></div>
                                <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
                                <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
                                <script>
                                    document.addEventListener("DOMContentLoaded", function() {
                                        // Initialize map
                                        var map = L.map("map").setView([0, 0], 2);
                                        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
                                            attribution: "© OpenStreetMap contributors"
                                        }).addTo(map);

                                        // Add markers
                                        var markers = [];
                                        ';
            // Generate marker JavaScript code
            foreach ($markers as $marker) {
                $popupContent = '<b><a href="index.php?p=userinfo&id='.htmlspecialchars($marker['peer_id']).'">'.htmlspecialchars($marker['callsign']).'</a></b><br>'
                              . htmlspecialchars($marker['location']).'<br>'
                              . 'TX: '.htmlspecialchars($marker['tx_freq']).'<br>'
                              . 'RX: '.htmlspecialchars($marker['rx_freq']);
                              
                echo 'var marker = L.marker(['.$marker['latitude'].', '.$marker['longitude'].'])
                            .bindPopup('.json_encode($popupContent).')
                            .addTo(map);
                      markers.push(marker);';
            }
            echo '
                                        // Adjust view to show all markers
                                        if (markers.length > 0) {
                                            var markerGroup = L.featureGroup(markers);
                                            map.fitBounds(markerGroup.getBounds());
                                        }
                                    });
                                </script>
                            </div>
                        </div>
                    </div>
                </div>';
        } else {
            echo '<p class="text-center">No stations found matching the criteria.</p>';
        }
    } catch (Exception $e) {
        echo "<p>Error accessing database: ".htmlspecialchars($e->getMessage())."</p>";
    }
    ?>
    <p id="hotspots"></p>
    <p id="footer"></p>
    <!-- this solves the footer issue -->
    <div><br></div>
</div>

<!-- this checks if id="lnksys" as content -->
<script>
    window.addEventListener('load', function () {
        setInterval(checkMainContent, 5000);
    });

    function checkMainContent() {
        var mainElement = document.getElementById('hotspots');
        if (mainElement && mainElement.innerHTML.trim() !== '') {
            // console.log('OKAY');
        } else {
            //console.log('NotOK');
            location.reload();
        }
    }
</script>