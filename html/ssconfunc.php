<?php
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
        $callsign = $conn->escapeString($username);
        $query = "SELECT int_id, callsign, psswd FROM Clients WHERE callsign = '$callsign' AND logged_in = 1";
        $result = $conn->query($query);
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
     
    function authenticateUserByIP()
    {
        $conn = connectDatabase();

        $query = "SELECT DISTINCT callsign FROM Clients WHERE host = '{$_SERVER['REMOTE_ADDR']}' AND logged_in = 1";
        $result = $conn->query($query);
     
        $callsign = "";
     
        // Only allow autologin if one callsign is logged from the client ip address
        if ($result->num_rows != 1) {
            return false;
        } else {
            while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
                $callsign = $row['callsign'];
            }
        }
     
        $query = "SELECT int_id, callsign, psswd FROM Clients WHERE callsign = '$callsign' AND logged_in = 1";
        $result = $conn->query($query);
        $int_ids = [];
        if ($result) {
            while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
                $_SESSION['user_id'] = $row['callsign'];
                $int_ids[] = $row['int_id'];
            }
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
