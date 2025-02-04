<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<div class="container">
    <div class="row justify-content-center">
      <div class="col-12">
        <div class="card">
          <div class="card-header border-transparent">
            <h3 class="card-title" id="tbl_srvrs">World Servers</h3>
          </div>
          <div class="card-body p-0">
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