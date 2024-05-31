#!/usr/bin/env python

import sys

from twisted.enterprise import adbapi
from twisted.internet.defer import inlineCallbacks

class ProxyDB:
    def __init__(self, db_path):
        self.db_path = db_path
        self.dbpool = adbapi.ConnectionPool("sqlite3", db_path, check_same_thread=False)

    @inlineCallbacks
    def make_clients_tbl(self):
        try:
            yield self.dbpool.runOperation(
                '''CREATE TABLE IF NOT EXISTS Clients(
                int_id INTEGER UNIQUE PRIMARY KEY NOT NULL,
                dmr_id BLOB NOT NULL,
                callsign VARCHAR(10) NOT NULL,
                host VARCHAR(15),
                options VARCHAR(100),
                opt_rcvd INTEGER DEFAULT 0 NOT NULL,
                mode INTEGER DEFAULT 4 NOT NULL,
                logged_in INTEGER DEFAULT 0 NOT NULL,
                modified INTEGER DEFAULT 0 NOT NULL,
                psswd BLOB,
                last_seen INTEGER NOT NULL)''')

        except Exception as err:
            print(f"make_clients_tbl error: {err}")

    @inlineCallbacks
    def test_db(self, _reactor):
        try:
            res = yield self.dbpool.runQuery("SELECT 1")
            if res:
                self.updt_tbl("start")
                print("Database connection test: OK")

        except Exception as err:
            if _reactor.running:
                print(f"Database connection error: {err}, stopping the reactor.")
                _reactor.stop()
            else:
                sys.exit(f"Database connection error: {err}, exiting.")

    @inlineCallbacks
    def ins_conf(self, int_id, dmr_id, callsign, host, mode):
        try:
            yield self.dbpool.runOperation(
                '''INSERT OR IGNORE INTO Clients (
                int_id, dmr_id, callsign, host, mode, logged_in, last_seen, psswd)
                VALUES (?, ?, ?, ?, ?, 1, strftime('%s', 'now'), NULL)
                ON CONFLICT(int_id) DO UPDATE SET
                callsign = excluded.callsign,
                host = excluded.host,
                mode = excluded.mode,
                logged_in = 1,
                opt_rcvd = 0,
                last_seen = strftime('%s', 'now'),
                psswd = NULL''',
                (int_id, dmr_id, callsign, host, mode))

        except Exception as err:
            print(f"ins_conf error: {err}")

    @inlineCallbacks
    def clean_tbl(self):
        try:
            yield self.dbpool.runOperation(
                "DELETE FROM Clients WHERE last_seen < strftime('%s', 'now', '-7 days')")

        except Exception as err:
            print(f"clean_tbl error: {err}")

    def slct_db(self):
        return self.dbpool.runQuery(
            "SELECT dmr_id, options FROM Clients WHERE modified = 1 and logged_in = 1")

    def slct_opt(self, _peer_id):
        return self.dbpool.runQuery("SELECT options FROM Clients WHERE dmr_id = ?", (_peer_id,))

    @inlineCallbacks
    def updt_tbl(self, actn, dmr_id=None, psswd=None):
        try:
            if actn == "start":
                yield self.dbpool.runOperation("UPDATE Clients SET logged_in=0, opt_rcvd=0")
            elif actn == "opt_rcvd":
                yield self.dbpool.runOperation(
                    "UPDATE Clients SET opt_rcvd = 1, options = NULL WHERE dmr_id = ?",
                    (dmr_id,))
            elif actn == "last_seen":
                yield self.dbpool.runOperation(
                    "UPDATE Clients SET last_seen = strftime('%s', 'now') WHERE dmr_id = ? and logged_in = 1",
                    (dmr_id,))
            elif actn == "log_out":
                yield self.dbpool.runOperation(
                    "UPDATE Clients SET logged_in = 0, modified = 0 WHERE dmr_id = ?",
                    (dmr_id,))
            elif actn == "rst_mod":
                yield self.dbpool.runOperation(
                    "UPDATE Clients SET modified = 0 WHERE dmr_id = ?", (dmr_id,))
            elif actn == "psswd":
                yield self.dbpool.runOperation(
                    "UPDATE Clients SET psswd = ? WHERE dmr_id = ?", (psswd, dmr_id))

        except Exception as err:
            print(f"updt_tbl error: {err}")

    @inlineCallbacks
    def updt_lstseen(self, dmrid_list):
        try:
            def db_actn(txn):
                txn.executemany(
                    "UPDATE Clients SET last_seen = strftime('%s', 'now') WHERE dmr_id = ?", dmrid_list)
            yield self.dbpool.runInteraction(db_actn)

        except Exception as err:
            print(f"updt_lstseen error: {err}")


if __name__ == "__main__":
    db_test = ProxyDB('/opt/adn-dashboard/html/db/dashboard.db')
    print(db_test)
