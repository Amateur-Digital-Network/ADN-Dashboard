<div class="container">
    <div class="row justify-content-center">
      <div class="col-12">
        <div class="card">
          <div class="card-header border-transparent">
            <h3 class="card-title" id="tbl_tgs"></h3>
          </div>
          <div class="card-body p-0">
          <?php
						$json_file = file_get_contents('https://adn.systems/files/talkgroup_ids.json');
						$data = json_decode($json_file, true);
						usort($data['results'], function ($a, $b) {
							return substr($a['tgid'], 0, 3) - substr($b['tgid'], 0, 3);
						});
						$total_items = count($data['results']);
							?>
            <div class="table-responsive p-1">
              <table class="table m-0 table-striped table-sm table-bordered" >
                <thead>
                  <tr>
                    <th style="width: 25px;" ></th>
                    <th id="tbrdgs_tg"></th>
                    <th id="tbrdgs_name"></th>
                  </tr>
                </thead>
                <tbody>
                <?php foreach ($data['results'] as $item) { ?>
										<?php $flag_image = "../flags/" . substr($item['tgid'], 0, 3) . ".png"; ?>
											<tr>
												<?php echo "<td><img src='$flag_image' alt='Flag'></td>"; ?>
												<td><?php echo $item['tgid']; ?></td>
												<td><?php echo $item['callsign']; ?></td>
											</tr>
										<?php } ?>
                </tbody>
                <tfoot class="text-center">
                    <td colspan="3"><span>Number of TalkGroups:</span> <?php echo $total_items; ?></td>
                </tfoot>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>