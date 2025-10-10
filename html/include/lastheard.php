
<div class="container">

    <!-- iz6rnd -->
    <div id="log" style="display: none;"></div>
    
    <p id="lsthrd_log"></p>
    
</div>

<!-- this checks if id="lsthrd_log" as content -->

<script>
  window.addEventListener('load', function () {
    var log_box = document.getElementById('log');
    // if (log_box) log_box.innerHTML = ""; // iz6rnd
    setInterval(checkMainContent, 5000);
  });

  function checkMainContent() {
    var mainElement = document.getElementById('lsthrd_log');
    if (mainElement && mainElement.innerHTML.trim() !== '') {
    // if (mainElement) { -- iz6rnd
      // console.log('OKAY');
    } else {
      // console.log('NotOK');
      location.reload();
    }
  }
</script>

