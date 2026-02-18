<div class="container">
    <p id="stats"></p>
    <?php
    if ($peer_id) {
        try {
            $db = new SQLite3('db/dashboard.db');
            $stmt = $db->prepare('SELECT * FROM masters_table WHERE peer_id = :peer_id');
            $stmt->bindValue(':peer_id', $peer_id, SQLITE3_INTEGER);
            $result = $stmt->execute();
            $row = $result->fetchArray(SQLITE3_ASSOC);

            if ($row) {
                // Show map if coordinates exist
                if (!empty($row['latitude']) && !empty($row['longitude'])) {
                    
                    // === LÓGICA DE SELECCIÓN DE ICONO (del segundo PHP) ===
                    $icon = 'img/default.png'; // Default por defecto
                    
                    if (strlen($row['peer_id']) == 6) {
                        $icon = 'img/antenna.png'; // Antena para ID de 6 dígitos (repetidor)
                    } elseif (strlen($row['peer_id']) > 6 && $row['tx_freq'] != 'N/A' && $row['rx_freq'] != 'N/A') {
                        $icon = 'img/hotspot.png'; // Hotspot para ID >6 dígitos con frecuencias
                    } elseif (strlen($row['peer_id']) > 6 && $row['tx_freq'] == 'N/A' && $row['rx_freq'] == 'N/A') {
                        $icon = 'img/bridge.png'; // Bridge para ID >6 dígitos sin frecuencias
                    }
                    // =====================================================

                    echo '  <div class="row justify-content-center">
                                <div class="col-12">
                                    <div class="card">
                                        <div class="card-body p-0">';
                    echo '                  <div id="map" style="height: 400px; width: 100%; margin-top: 20px;"></div>';
                    
                    // Add Leaflet.js map script con icono personalizado
                    echo '
                    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
                    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
                    <script>
                        document.addEventListener("DOMContentLoaded", function() {
                            var map = L.map("map").setView(['.$row['latitude'].', '.$row['longitude'].'], 13);
                            
                            L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
                                attribution: "&copy; OpenStreetMap contributors"
                            }).addTo(map);

                            // === ICONO PERSONALIZADO BASADO EN TIPO DE ESTACIÓN ===
                            var customIcon = L.icon({
                                iconUrl: "'.htmlspecialchars($icon).'",
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -32]
                            });

                            L.marker(['.$row['latitude'].', '.$row['longitude'].'], { icon: customIcon })
                            .addTo(map)
                            .bindPopup("<b>'.htmlspecialchars($row['callsign']).'</b><br>'.
                                        htmlspecialchars($row['location']).'<br>'.
                                        '<b>TX: </b>' . htmlspecialchars($row['tx_freq']).'<br>'.
                                        '<b>RX: </b>' . htmlspecialchars($row['rx_freq']).'")
                            .openPopup();
                            // =====================================================
                        });
                    </script>';
                } else {
                    echo "<p>No location coordinates available.</p>";
                }
                
                // Show user info (sin cambios)
                echo '                      <h3 class="text-center">' . htmlspecialchars($row['callsign']) . '</h3>
                                            <div class="table-responsive">
                                                <table class="table m-0 table-striped table-sm">
                                                    <tbody>
                                                        <tr>
                                                            <th>Radio ID</th>
                                                            <td>' . htmlspecialchars($row['peer_id']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Location</th>
                                                            <td>' . htmlspecialchars($row['location']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Country</th>
                                                            <td>' . htmlspecialchars($row['description']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Height</th>
                                                            <td>' . htmlspecialchars($row['height']) . ' m</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Site</th>
                                                            <td><a target="_blank" href="' . htmlspecialchars($row['url']) . '">' . htmlspecialchars($row['url']) . '</a></td>
                                                        </tr>
                                                        <tr>
                                                            <th>Type</th>
                                                            <td>' . htmlspecialchars($row['slots']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>TX Frequency</th>
                                                            <td>' . htmlspecialchars($row['tx_freq']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>RX Frequency</th>
                                                            <td>' . htmlspecialchars($row['rx_freq']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Color Code</th>
                                                            <td>' . htmlspecialchars($row['colorcode']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>TX Power</th>
                                                            <td>' . htmlspecialchars($row['tx_power']) . ' Watts</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Interface</th>
                                                            <td>' . htmlspecialchars($row['package_id']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Software</th>
                                                            <td>' . htmlspecialchars($row['software_id']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>Connected</th>
                                                            <td>' . htmlspecialchars($row['connected']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>TS1 Static TGs</th>
                                                            <td>' . htmlspecialchars($row['ts1_static']) . '</td>
                                                        </tr>
                                                        <tr>
                                                            <th>TS2 Static TGs</th>
                                                            <td>' . htmlspecialchars($row['ts2_static']) . '</td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                ';
            } else {
                echo "<p>No records found for Peer ID: " . htmlspecialchars($peer_id) . "</p>";
            }
            
            $db->close();
        } catch (Exception $e) {
            echo "<p>Error accessing database: " . htmlspecialchars($e->getMessage()) . "</p>";
        }
    } else {
        echo "<p>No Peer ID specified. Please provide a Peer ID parameter.</p>";
    }
?>
</div>