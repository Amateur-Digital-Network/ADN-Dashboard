<div class="container">
    <p id="stats"></p>
    <p id="brdg"></p>
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
        var mainElement = document.getElementById('brdg');
        if (mainElement && mainElement.innerHTML.trim() !== '') {
            // console.log('OKAY');
        } else {
            //console.log('NotOK');
            location.reload();
        }
    }
</script>