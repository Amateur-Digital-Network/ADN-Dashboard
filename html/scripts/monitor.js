var sock = null;
var ellog = null;
const conf_groups = [];

window.onload = function () {
    var wsuri;
    conf_id();

    ellog = document.getElementById('log');

    main_tbl = document.getElementById('main');
    opb_tbl = document.getElementById('opb');
    statictg_tbl = document.getElementById('statictg');
    tgcount_tbl = document.getElementById('tgcount');
    lsthrd_log_tbl = document.getElementById('lsthrd_log');
    status_box = document.getElementById('stats');
    activity_box = document.getElementById('activity');
    repeaters_tbl = document.getElementById('repeaters');
    brdg_tbl = document.getElementById('brdg');
    hotspots_tbl = document.getElementById('hotspots');
    peers_tbl = document.getElementById('peers');
    footer_box = document.getElementById('footer');

    wsuri = (((window.location.protocol === "https:") ? "wss://" : "ws://") + window.location.hostname + ":9000");

    if ("WebSocket" in window) {
        sock = new WebSocket(wsuri);
    } else if ("MozWebSocket" in window) {
        sock = new MozWebSocket(wsuri);
    } else {
        if (ellog != null) {
            log("Browser does not support WebSocket!");
        }
    }

    if (sock) {
        sock.onopen = function () {
            if (conf_groups.length > 0) {
                sock.send("conf," + conf_groups);
            }
            if (ellog != null) {
                log("Connected to " + wsuri);
            }
        }

        sock.onclose = function (e) {
            if (ellog != null) {
                log("Connection closed (wasClean = " + e.wasClean + ", code = " + e.code + ", reason = '" + e.reason + "')");
            }
            sock = null;
            for (i = 0; i < conf_groups.length; i++) {
                var group = conf_groups[i];
                if (group == 'main') {
                    main_tbl.innerHTML = "";
                } else if (group == 'opb') {
                    opb_tbl.innerHTML = "";
                } else if (group == 'statictg') {
                    statictg_tbl.innerHTML = "";
                } else if (group == 'tgcount') {
                    tgcount_tbl.innerHTML = "";
                } else if (group == 'lsthrd_log') {
                    lsthrd_log_tbl.innerHTML = "";
                } else if (group == 'status') {
                    status_box.innerHTML = "";
                } else if (group == 'activity') {
                    activity_box.innerHTML = "";
                } else if (group == 'repeaters') {
                    repeaters_tbl.innerHTML = "";
                } else if (group == 'brdg') {
                    brdg_tbl.innerHTML = "";
                } else if (group == 'hotspots') {
                    hotspots_tbl.innerHTML = "";
                } else if (group == 'peers') {
                    peers_tbl.innerHTML = "";
                } else if (group == 'footer') {
                    footer_box.innerHTML = "";
                }
            }
        }

        sock.onmessage = function (e) {
            var opcode = e.data.slice(0, 1);
            var message = e.data.slice(1);
            if (opcode == "t") {
                Tmsg(message)
            } else if (opcode == "i") {
                Imsg(message);
            } else if (opcode == "o") {
                Omsg(message);
            } else if (opcode == "s") {
                Smsg(message);
            } else if (opcode == 'h') {
                Hmsg(message);
            } else if (opcode == 'x') {
                Xmsg(message);
            } else if (opcode == 'a') {
                Amsg(message);
            } else if (opcode == 'r') {
                Rmsg(message);
            } else if (opcode == 'z') {
                Zmsg(message);
            } else if (opcode == 'h') {
                Hmsg(message);
            } else if (opcode == 'p') {
                Pmsg(message);
            } else if (opcode == 'f') {
                Fmsg(message);
            } else if (opcode == "l") {
                if (ellog != null) {
                    log(message);
                }
            } else if (opcode == "q") {
                log(message);
                for (i = 0; i < conf_groups.length; i++) {
                    var group = conf_groups[i];
                    if (group == "main") {
                        main_tbl.innerHTML = "";
                    } else if (group == "opb") {
                        opb_tbl.innerHTML = "";
                    } else if (group == 'statictg') {
                        statictg_tbl.innerHTML = "";
                    } else if (group == "tgcount") {
                        tgcount_tbl.innerHTML = "";
                    } else if (group == 'lsthrd_log') {
                        lsthrd_log_tbl.innerHTML = "";
                    } else if (group == 'stats') {
                        status_box.innerHTML = "";
                    } else if (group == 'activity') {
                        activity_box.innerHTML = "";
                    } else if (group == 'repeaters') {
                        repeaters_tbl.innerHTML = "";
                    } else if (group == 'brdg') {
                        brdg_tbl.innerHTML = "";
                    } else if (group == 'hotspots') {
                        hotspots_tbl.innerHTML = "";
                    } else if (group == 'peers') {
                        peers_tbl.innerHTML = "";
                    } else if (group == 'footer') {
                        footer_box.innerHTML = "";
                    }
                }
            } else {
                log("Unknown Message Received: " + message);
            }
        }
    }
};

function Imsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
            const languageSelect = document.getElementById('languageSelect');

            // Function to translate the page based on the selected language
            function translatePage() {
                const selectedLanguage = languageSelect.value;
                Object.keys(translations).forEach(key => {
                    const element = document.getElementById(key);
                    if (element) {
                        const translation = translations[key][selectedLanguage];
                        element.textContent = translation;
                    }
                });
            }

            // Update the content after translations are loaded
            main_tbl.innerHTML = _msg;

            // Translate the page on initial load
            translatePage();

            // Translate the page when the language selection changes
            languageSelect.addEventListener('change', translatePage);
        });
}

function Omsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
            const languageSelect = document.getElementById('languageSelect');
            //const opb_tbl = document.getElementById('opb_tbl');

            // Function to translate the page based on the selected language
            function translatePage() {
                const selectedLanguage = languageSelect.value;
                Object.keys(translations).forEach(key => {
                    const element = document.getElementById(key);
                    if (element) {
                        const translation = translations[key][selectedLanguage];
                        element.textContent = translation;
                    }
                });
            }

            // Update the content after translations are loaded
            opb_tbl.innerHTML = _msg;

            // Translate the page on initial load
            translatePage();

            // Translate the page when the language selection changes
            languageSelect.addEventListener('change', translatePage);
        });
}

function Smsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
            const languageSelect = document.getElementById('languageSelect');
            //const statictg_tbl = document.getElementById('statictg_tbl');

            // Function to translate the page based on the selected language
            function translatePage() {
                const selectedLanguage = languageSelect.value;
                Object.keys(translations).forEach(key => {
                    const element = document.getElementById(key);
                    if (element) {
                        const translation = translations[key][selectedLanguage];
                        element.textContent = translation;
                    }
                });
            }

            // Update the content after translations are loaded
            statictg_tbl.innerHTML = _msg;

            // Translate the page on initial load
            translatePage();

            // Translate the page when the language selection changes
            languageSelect.addEventListener('change', translatePage);
        });
}

function Hmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
            const languageSelect = document.getElementById('languageSelect');
            //const lsthrd_log_tbl = document.getElementById('lsthrd_log_tbl');

            // Function to translate the page based on the selected language
            function translatePage() {
                const selectedLanguage = languageSelect.value;
                Object.keys(translations).forEach(key => {
                    const element = document.getElementById(key);
                    if (element) {
                        const translation = translations[key][selectedLanguage];
                        element.textContent = translation;
                    }
                });
            }

            // Update the content after translations are loaded
            lsthrd_log_tbl.innerHTML = _msg;

            // Translate the page on initial load
            translatePage();

            // Translate the page when the language selection changes
            languageSelect.addEventListener('change', translatePage);
        });
}

function Tmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
            const languageSelect = document.getElementById('languageSelect');
            //const tgcount_tbl = document.getElementById('tgcount_tbl');

            // Function to translate the page based on the selected language
            function translatePage() {
                const selectedLanguage = languageSelect.value;
                Object.keys(translations).forEach(key => {
                    const element = document.getElementById(key);
                    if (element) {
                        const translation = translations[key][selectedLanguage];
                        element.textContent = translation;
                    }
                });
            }

            // Update the content after translations are loaded
            tgcount_tbl.innerHTML = _msg;

            // Translate the page on initial load
            translatePage();

            // Translate the page when the language selection changes
            languageSelect.addEventListener('change', translatePage);
        });
}

function Xmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
            const languageSelect = document.getElementById('languageSelect');
            //const tgcount_tbl = document.getElementById('tgcount_tbl');

            // Function to translate the page based on the selected language
            function translatePage() {
                const selectedLanguage = languageSelect.value;
                Object.keys(translations).forEach(key => {
                    const element = document.getElementById(key);
                    if (element) {
                        const translation = translations[key][selectedLanguage];
                        element.textContent = translation;
                    }
                });
            }

            // Update the content after translations are loaded
            status_box.innerHTML = _msg;

            // Translate the page on initial load
            translatePage();

            // Translate the page when the language selection changes
            languageSelect.addEventListener('change', translatePage);
        });
}

function Amsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
        const languageSelect = document.getElementById('languageSelect');
        //const tgcount_tbl = document.getElementById('tgcount_tbl');

        // Function to translate the page based on the selected language
        function translatePage() {
            const selectedLanguage = languageSelect.value;
            Object.keys(translations).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    const translation = translations[key][selectedLanguage];
                    element.textContent = translation;
                }
            });
        }

        // Update the content after translations are loaded
        activity_box.innerHTML = _msg;

        // Translate the page on initial load
        translatePage();

        // Translate the page when the language selection changes
        languageSelect.addEventListener('change', translatePage);
    });
}

function Rmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
        const languageSelect = document.getElementById('languageSelect');
        //const tgcount_tbl = document.getElementById('tgcount_tbl');

        // Function to translate the page based on the selected language
        function translatePage() {
            const selectedLanguage = languageSelect.value;
            Object.keys(translations).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    const translation = translations[key][selectedLanguage];
                    element.textContent = translation;
                }
            });
        }

        // Update the content after translations are loaded
        repeaters_tbl.innerHTML = _msg;

        // Translate the page on initial load
        translatePage();

        // Translate the page when the language selection changes
        languageSelect.addEventListener('change', translatePage);
    });
}

function Zmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
        const languageSelect = document.getElementById('languageSelect');
        //const tgcount_tbl = document.getElementById('tgcount_tbl');

        // Function to translate the page based on the selected language
        function translatePage() {
            const selectedLanguage = languageSelect.value;
            Object.keys(translations).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    const translation = translations[key][selectedLanguage];
                    element.textContent = translation;
                }
            });
        }

        // Update the content after translations are loaded
        brdg_tbl.innerHTML = _msg;

        // Translate the page on initial load
        translatePage();

        // Translate the page when the language selection changes
        languageSelect.addEventListener('change', translatePage);
    });
}

function Hmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
        const languageSelect = document.getElementById('languageSelect');
        //const tgcount_tbl = document.getElementById('tgcount_tbl');

        // Function to translate the page based on the selected language
        function translatePage() {
            const selectedLanguage = languageSelect.value;
            Object.keys(translations).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    const translation = translations[key][selectedLanguage];
                    element.textContent = translation;
                }
            });
        }

        // Update the content after translations are loaded
        hotspots_tbl.innerHTML = _msg;

        // Translate the page on initial load
        translatePage();

        // Translate the page when the language selection changes
        languageSelect.addEventListener('change', translatePage);
    });
}

function Pmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
        const languageSelect = document.getElementById('languageSelect');
        //const tgcount_tbl = document.getElementById('tgcount_tbl');

        // Function to translate the page based on the selected language
        function translatePage() {
            const selectedLanguage = languageSelect.value;
            Object.keys(translations).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    const translation = translations[key][selectedLanguage];
                    element.textContent = translation;
                }
            });
        }

        // Update the content after translations are loaded
        peers_tbl.innerHTML = _msg;

        // Translate the page on initial load
        translatePage();

        // Translate the page when the language selection changes
        languageSelect.addEventListener('change', translatePage);
    });
}

function Fmsg(_msg) {
    fetch('translations.json')
        .then(response => response.json())
        .then(translations => {
        const languageSelect = document.getElementById('languageSelect');
        //const tgcount_tbl = document.getElementById('tgcount_tbl');

        // Function to translate the page based on the selected language
        function translatePage() {
            const selectedLanguage = languageSelect.value;
            Object.keys(translations).forEach(key => {
                const element = document.getElementById(key);
                if (element) {
                    const translation = translations[key][selectedLanguage];
                    element.textContent = translation;
                }
            });
        }

        // Update the content after translations are loaded
        footer_box.innerHTML = _msg;

        // Translate the page on initial load
        translatePage();

        // Translate the page when the language selection changes
        languageSelect.addEventListener('change', translatePage);
    });
}


// translate script
fetch('translations.json')
  .then(response => response.json())
  .then(translations => {
    const languageSelect = document.getElementById('languageSelect');

    // Function to translate the page based on the selected language
    function translatePage() {
        const selectedLanguage = languageSelect.value;
        Object.keys(translations).forEach(key => {
          const element = document.getElementById(key);
          if (element) {
            const translation = translations[key][selectedLanguage];
            if (element.getAttribute('data-bs-toggle') === 'tooltip') {
              element.setAttribute('data-bs-title', translation);
            } else if (element.tagName === 'INPUT') {
              element.setAttribute('placeholder', translation);
            } else {
              element.textContent = translation;
            }
          }
        });
  
        // Re-initialize Bootstrap tooltips after translation
        $('[data-bs-toggle="tooltip"]').tooltip();
    }

    // Translate the page on initial load
    translatePage();

    // Translate the page when the language selection changes
    languageSelect.addEventListener('change', translatePage);
  });


function log(_msg) {
    ellog.innerHTML += _msg + '\n';
    ellog.scrollTop = ellog.scrollHeight;
};

// Find tables that are present
function conf_id() {
    const groups = ["main", "opb", "statictg", "log", "lsthrd_log", "tgcount", "stats", "activity", "repeaters", "brdg", "hotspots", "peers", "footer"];
    const tags = [document.getElementsByTagName("p"), document.getElementsByTagName("pre")]
    for (i = 0; i < tags.length; i++) {
        for (j = 0; j < tags[i].length; j++)
            if (groups.includes(tags[i][j].id)) {
                conf_groups.push(tags[i][j].id);
            }
    }
    console.log(conf_groups)
};

