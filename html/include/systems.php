<div class="container">
    <p id="stats"></p>
    <?php
    try {
        $db = new SQLite3('db/dashboard.db');

        // Query for peers with valid frequencies
        $query = "SELECT * FROM masters_table";
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
                
                // Determine icon type based on peer_id length and frequencies
                if (strlen($row['peer_id']) == 6) {
                    $row['icon'] = 'img/antenna.png'; // Antenna icon
                } elseif (strlen($row['peer_id']) > 6 && $row['tx_freq'] != 'N/A' && $row['rx_freq'] != 'N/A') {
                    $row['icon'] = 'img/hotspot.png'; // Hotspot icon
                } elseif (strlen($row['peer_id']) > 6 && $row['tx_freq'] == 'N/A' && $row['rx_freq'] == 'N/A') {
                    $row['icon'] = 'images/bridge.png'; // Bridge icon
                } else {
                    $row['icon'] = 'images/default.png'; // Default icon (optional)
                }

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
                                        var map = L.map("map").setView([0, 0], 2);
                                        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
                                            attribution: "© OpenStreetMap contributors"
                                        }).addTo(map);

                                        var markers = [];
            ';

            // Generate marker JavaScript code
            foreach ($markers as $marker) {
                $popupContent = '<b><a href="index.php?p=userinfo&id='.htmlspecialchars($marker['peer_id']).'">'
                            . htmlspecialchars($marker['callsign']) . '</a></b><br>'
                            . htmlspecialchars($marker['location']) . '<br>'
                            . 'TX: ' . htmlspecialchars($marker['tx_freq']) . '<br>'
                            . 'RX: ' . htmlspecialchars($marker['rx_freq']);

                if (!empty($marker['icon'])) {
                    echo 'var customIcon = L.icon({
                                iconUrl: "'.htmlspecialchars($marker['icon']).'",
                                iconSize: [32, 32], 
                                iconAnchor: [16, 32], 
                                popupAnchor: [0, -32]
                            });

                            var marker = L.marker(['.$marker['latitude'].', '.$marker['longitude'].'], { icon: customIcon })
                                .bindPopup('.json_encode($popupContent).')
                                .addTo(map);
                            markers.push(marker);
                    ';
                } else {
                    echo 'var marker = L.marker(['.$marker['latitude'].', '.$marker['longitude'].'])
                                .bindPopup('.json_encode($popupContent).')
                                .addTo(map);
                            markers.push(marker);
                    ';
                }
            }

            echo '
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
    <p id="repeaters"></p>
    <p id="hotspots"></p>
    <p id="brdg"></p>
    <p id="peers"></p>
    <!-- this solves the footer issue -->
    <div><br></div>
</div>

<script>
  window.addEventListener('load', function () {
    setInterval(checkMainContent, 5000);
  });

  function checkMainContent() {
    var elementsToCheck = ['repeaters', 'hotspots', 'brdg', 'peers'];
    var contentExists = elementsToCheck.some(function(id) {
      var element = document.getElementById(id);
      return element && element.innerHTML.trim() !== '';
    });

    if (!contentExists) {
      // Reload the page
      location.reload();
    }
  }
</script>