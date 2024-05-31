<!-- Credits: Cortney T. Buffington, N0MJS 2013-2018 | https://github.com/tolitski/HBmonitor.git -->
<!-- Credits: KC1AWV 2019 | https://github.com/kc1awv/hbmonitor3.git-->
<!-- Credits: SP2ONG 2019-2022 | https://github.com/sp2ong/HBmonitor.git -->
<!-- Credits: OA4DOA 2022 | https://github.com/yuvelq/FDMR-Monitor.git -->
<!-- THIS COPYRIGHT NOTICE MUST BE DISPLAYED AS A CONDITION OF THE LICENCE GRANT FOR THIS SOFTWARE. ALL DERIVATEIVES WORKS MUST CARRY THIS NOTICE -->
<div class="text-center d-none d-sm-inline">
    <div>
        <?php
        if (isset($config['DASHBOARD']['FOOTER1']) && !empty($config['DASHBOARD']['FOOTER1'])) {
            $footer1Value = $config['DASHBOARD']['FOOTER1'];
            echo $footer1Value . ' | ';
        }
        ?><a title="CS8ABG Dash v24.06" href=https://github.com/Amateur-Digital-Network/ADN-Dashboard.git>CS8ABG</a> ADN Systems Dashboard
                        <?php
        if (isset($config['DASHBOARD']['FOOTER2']) && !empty($config['DASHBOARD']['FOOTER2'])) {
            $footer2Value = $config['DASHBOARD']['FOOTER2'];
            echo ' | ' . $footer2Value;
        }
        ?>
    </div>
</div>