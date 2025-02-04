<div class="container">
  <p id="stats"></p>
  <p id="activity"></p>
  <p id="main"></p>
  <p id="footer"></p>
</div>
<!-- this checks if id="main" as content -->
<script>
  window.addEventListener('load', function () {
    setInterval(checkMainContent, 5000);
  });

  function checkMainContent() {
    var mainElement = document.getElementById('main');
    if (mainElement && mainElement.innerHTML.trim() !== '') {
      // Content exists, do nothing
    } else {
      location.reload();
    }
  }

</script>
