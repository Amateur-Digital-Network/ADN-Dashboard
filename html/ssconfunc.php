<?php
authenticateUserByIP();
    // Connect to the database
    function connectDatabase()
    {
        $dbPath = 'db/dashboard.db';
        $conn = new SQLite3($dbPath);
        if (!$conn) {
            die("Connection failed: " . $conn->lastErrorMsg());
        }
        return $conn;
    }
    
    // Authenticate User
    function authenticateUser($username, $password)
    {
        $conn = connectDatabase();
        $query = "SELECT int_id, callsign, psswd FROM Clients WHERE callsign = ? COLLATE NOCASE AND logged_in = 1";
        $stmt = $conn->prepare($query);
        $stmt->bindValue(1, $username, SQLITE3_TEXT);
        $result = $stmt->execute();
        
        $int_ids = [];
        if ($result) {
            while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
                $storedPassword = $row['psswd'];
                if (hash_pbkdf2("sha256", $password, "HamDMR", 2000) === $storedPassword) {
                    $_SESSION['user_id'] = $row['callsign'];
                    $int_ids[] = $row['int_id'];
                }
            }
        }
        
        if (!empty($int_ids)) {
            $_SESSION['int_ids'] = array_unique($int_ids, SORT_NUMERIC);
            return true;
        } else {
            return false;
        }
    }
     
    // Autenticate with IP Address
    function authenticateUserByIP()
    {
        $conn = connectDatabase();
        $stmt = $conn->prepare("SELECT DISTINCT callsign FROM Clients WHERE host = :host AND logged_in = 1");
        $stmt->bindValue(':host', $_SERVER['REMOTE_ADDR'], SQLITE3_TEXT);
        $result = $stmt->execute();
        $callsign = "";
        $callsigns = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            $callsigns[] = $row['callsign'];
        }
        
        if (count($callsigns) != 1) {
            return false;
        } else {
            $callsign = $callsigns[0];
        }
         
        $stmt = $conn->prepare("SELECT int_id, callsign, psswd FROM Clients WHERE callsign = :callsign AND logged_in = 1");
        $stmt->bindValue(':callsign', $callsign, SQLITE3_TEXT);
        $result = $stmt->execute();
        
        $int_ids = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            $_SESSION['user_id'] = $row['callsign'];
            $int_ids[] = $row['int_id'];
        }
         
        if (!empty($int_ids)) {
            $_SESSION['int_ids'] = array_unique($int_ids, SORT_NUMERIC);
            return true;
        } else {
            return false;
        }
    }

    // Session timeout
    function checkSessionTimeout()
    {
        $timeout = 3600; // You have 1 hour TGTFO
        if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity'] > $timeout)) {
            session_unset();
            session_destroy();
            header("Location: sslogin.php");
            exit();
        }
        $_SESSION['last_activity'] = time();
    }

    // Get device details from db
    function getDevDetails($intId)
    {
        $conn = connectDatabase();
        $intId = $conn->escapeString($intId);

        $query = "SELECT * FROM Clients WHERE int_id = '$intId'";
        $result = $conn->query($query);

        if ($result) {
            $devDetails = $result->fetchArray(SQLITE3_ASSOC);
            if ($devDetails) {
                return $devDetails;
            }
        }

        return null;
    }

    // Update device options in db
    function updateDevOptions($intId, $options)
    {
        $conn = connectDatabase();
        $intId = $conn->escapeString($intId);
        $options = $conn->escapeString($options);

        $query = "UPDATE Clients SET options = '$options', modified = 1 WHERE int_id = '$intId'";
        $result = $conn->query($query);

        return $result;
    }
?>
