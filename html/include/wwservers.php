<div class="container">
    <div class="row justify-content-center">
      <div class="col-12">
        <div class="card">
          <div class="card-header border-transparent">
            <h3 class="card-title" id="tbl_srvrs">World Servers</h3>
          </div>
          <div class="card-body p-0">
            <div id="map" style="height: 450px;"></div><br/>
            <div class="table-responsive">
              <table class="table m-0 table-striped table-sm">
                <thead>
                  <tr>
                    <th style="width: 25px;"></th>
                    <th id="tsrvrs_country"></th>
                    <th id="tsrvrs_dmrid"></th>
                    <th id="tsrvrs_ipname"></th>
                    <th id="tsrvrs_pass"></th>
                    <th id="tsrvrs_port"></th>
                    <th id="tsrvrs_status" colspan="2" style="text-align: center;"></th>
                  </tr>
                </thead>
                <tbody>
                <?php
                  $url = 'https://adn.systems/servers/status.json';
                  $data = file_get_contents($url);
                  $servers = json_decode($data, true)['servers'];

                  // Array to store country-wise server status
                  $country_status = array();

                  foreach ($servers as $server) {
                      $country = $server['name'];
                      $id = $server['network'];
                      $host = $server['server'];
                      $password = $server['password'];
                      $port = $server['port'];
                      $status = $server['status'];
                      $login_ok = $server['login_ok'];
                      $status_code = $server['status_code'];
                      $timestamp = $server['timestamp'];
                      $flag_image = "../flags/" . substr($id, 0, 3) . ".png";
                      // Store country-wise server status
                      $country_status[$country][] = array(
                          'host' => $host,
                          'status' => $status,
                          'login_ok' => $login_ok
                      );
                      echo '<tr>';
                      echo "<td><img src='$flag_image' alt='Flag'></td>";
                      echo '<td>' . htmlspecialchars($country) . '</td>';
                      echo '<td>' . htmlspecialchars($id) . '</td>';
                      echo '<td>' . htmlspecialchars($host) . '</td>';
                      echo '<td>' . htmlspecialchars($password) . '</td>';
                      echo '<td>' . htmlspecialchars($port) . '</td>';
                      if ($status == 'online') {
                          echo '<td style="text-align: center;"><span class="badge badge-success">Online</span></td>';
                      } else {
                          if ($status_code == 1) {
                              $status_err = "1 - Login OK";
                          } elseif ($status_code == 2) {
                              $status_err = "2 - Login Rejected";
                          } elseif ($status_code == 3) {
                              $status_err = "3 - Unexpected Response";
                          } elseif ($status_code == 4) {
                              $status_err = "4 - Cannot Connect";
                          }
                          echo '<td style="text-align: center;"><span class="badge badge-danger" title="' . $status_err . '">Offline</span></td>';
                      }
                      if ($login_ok) {
                          echo '<td style="text-align: center;"><span class="badge badge-success">Online</span></td>';
                      } else {
                          if ($status_code == 1) {
                              $status_err = "1 - Login OK";
                          } elseif ($status_code == 2) {
                              $status_err = "2 - Login Rejected";
                          } elseif ($status_code == 3) {
                              $status_err = "3 - Unexpected Response";
                          } elseif ($status_code == 4) {
                              $status_err = "4 - Cannot Connect";
                          }
                          echo '<td style="text-align: center;"><span class="badge badge-danger" title="' . $status_err . '">Offline</span></td>';
                      }
                      echo '</tr>';
                  }
              ?>
                </tbody>
                <tfoot>
                    <td colspan="8"><span>Number of Servers:</span> <?php echo isset($lineCount) ? $lineCount : count($servers); ?></td>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDq-o0NuOP7gfDZi1qC-bzgRGhzgBZ7DFc&callback=initMap" async defer></script>

<script>
    var geocoder;
    var map;

    function initMap() {
        geocoder = new google.maps.Geocoder();
        map = new google.maps.Map(document.getElementById('map'), {
            center: {
                lat: 15,
                lng: 20
            },
            zoom: 2,
            streetViewControl: false,
            scrollwheel: true
        });

        <?php
        foreach ($country_status as $country => $servers) {
            $status = "Offline";
            $color = "red";

            foreach ($servers as $server) {
                if ($server['status'] == 'online' && $server['login_ok']) {
                    $status = "Online";
                    $color = "green";
                    break;
                } elseif ($server['status'] == 'online' && !$server['login_ok']) {
                    $status = "Login Rejected";
                    $color = "yellow";
                    break;
                }
            }
            $country_without_suffix = str_replace(['_Central', '_Multiprotocol'], '', $country);
            // Geocode country
            echo "geocoder.geocode({'address': '" . $country_without_suffix . "'}, function(results, status) {";
            echo "if (status === 'OK') {";
            echo "var marker = new google.maps.Marker({";
            echo "map: map,";
            echo "position: results[0].geometry.location,";
            echo "title: '" . $country . "\\n=== " . $status . " ===',";
            echo "animation: google.maps.Animation.DROP,";
            echo "icon: 'http://maps.google.com/mapfiles/ms/icons/" . $color . ".png'";
            echo "});";
            echo "} else {";
            echo "console.error('Geocode was not successful for the following reason: ' + status);";
            echo "}";
            echo "});";
        }
        ?>
    }
</script>