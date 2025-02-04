<div class="container">
  <p id="stats"></p>
  <p id="opb"></p>
  <p id="footer"></p>
  <!-- this solves the footer issue -->
  <div><br></div>
</div>

<!-- this checks if id="opb" as content -->
<script>
  window.addEventListener('load', function () {
    setInterval(checkMainContent, 5000);
  });

  function checkMainContent() {
    var mainElement = document.getElementById('opb');
    if (mainElement && mainElement.innerHTML.trim() !== '') {
      // console.log('OKAY');
    } else {
      //console.log('NotOK');
      location.reload();
    }
  }
</script>