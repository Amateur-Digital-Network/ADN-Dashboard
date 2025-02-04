#!/usr/bin/env python
###############################################################################
#   Copyright (C) 2024 Bruno Farias, CS8ABG <cs8abg@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
###############################################################################

__author__     = 'Bruno, CS8ABG'
__version__    = '24.05'
__copyright__  = 'Copyright (c) Bruno, CS8ABG'
__license__    = 'GNU GPLv3'
__maintainer__ = 'Bruno, CS8ABG'
__email__      = 'cs8abg@gmail.com'

import logging
from json import loads as jloads
from sys import exit as sys_exit
from twisted.enterprise import adbapi
from twisted.internet.defer import inlineCallbacks, returnValue
from datetime import date, datetime, timedelta

logger = logging.getLogger("dashboard")

# Format seconds into H:M:S
def sec_time(_time):
    _time = int(_time)
    seconds = _time % 60
    minutes = int(_time/60) % 60
    hours = int(_time/60/60) % 24
    if hours:
        return f'{hours}h {minutes}m'
    elif minutes:
        return f'{minutes}m {seconds}s'
    else:
        return f'{seconds}s'


class DashDB:
    def __init__(self, db_name):
        self.db = adbapi.ConnectionPool("sqlite3", db_name, check_same_thread=False)

    # Add these methods to the DashDB class in dash_db.py
    @inlineCallbacks
    def export_ctable_to_db(self, ctable):
        try:
            def create_tables(txn):
                # Masters Table
                txn.execute('''CREATE TABLE IF NOT EXISTS masters_table (
                                peer_id INT PRIMARY KEY,
                                master_name TEXT NOT NULL,
                                callsign TEXT,
                                location TEXT,
                                description TEXT,
                                ip TEXT,
                                port INT,
                                connected TEXT,
                                slots TEXT,
                                tx_freq TEXT,
                                rx_freq TEXT,
                                package_id TEXT,
                                software_id TEXT,
                                url TEXT,
                                colorcode TEXT,
                                tx_power TEXT,
                                latitude TEXT,
                                longitude TEXT,
                                height TEXT,
                                connection TEXT,
                                ts1 TEXT,
                                ts2 TEXT,
                                ts1_static TEXT,
                                ts2_static TEXT,
                                single_ts1 TEXT,
                                single_ts2 TEXT,
                                timeout_ts1 TEXT,
                                timeout_ts2 TEXT,
                                last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
                
                # Peers Table
                txn.execute('''CREATE TABLE IF NOT EXISTS peers_table (
                                peer_name TEXT PRIMARY KEY,
                                callsign TEXT,
                                location TEXT,
                                description TEXT,
                                master_ip TEXT,
                                master_port INT,
                                connection_status TEXT,
                                connected TEXT,
                                pings_sent INT,
                                pings_ackd INT,
                                slots TEXT,
                                ts1 TEXT,
                                ts2 TEXT,
                                last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
                
                # OpenBridges Table
                txn.execute('''CREATE TABLE IF NOT EXISTS openbridges_table (
                                network_id INT PRIMARY KEY,
                                bridge_name TEXT,
                                target_ip TEXT,
                                target_port INT,
                                last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
            
            yield self.db.runInteraction(create_tables)

            def insert_data(txn):
                now = datetime.now()
                
                # Insert or Update Masters Table
                for master, data in ctable["MASTERS"].items():
                    for peer_id, peer_data in data["PEERS"].items():
                        txn.execute('''INSERT INTO masters_table
                                        (peer_id, master_name, callsign, location, description, ip, port, connected, slots, tx_freq, rx_freq, package_id,
                                        software_id, url, colorcode, tx_power, latitude, longitude, height, connection, ts1, ts2, ts1_static, 
                                        ts2_static, single_ts1, single_ts2, timeout_ts1, timeout_ts2, last_seen)
                                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                                        ON CONFLICT(peer_id) DO UPDATE SET
                                        master_name=excluded.master_name, callsign=excluded.callsign, location=excluded.location, description=excluded.description,
                                        ip=excluded.ip, port=excluded.port, connected=excluded.connected, slots=excluded.slots, tx_freq=excluded.tx_freq, 
                                        rx_freq=excluded.rx_freq, package_id=excluded.package_id,
                                        software_id=excluded.software_id, url=excluded.url, colorcode=excluded.colorcode, tx_power=excluded.tx_power,
                                        latitude=excluded.latitude, longitude=excluded.longitude, height=excluded.height, connection=excluded.connection,
                                        ts1=excluded.ts1, ts2=excluded.ts2, ts1_static=excluded.ts1_static, ts2_static=excluded.ts2_static, 
                                        single_ts1=excluded.single_ts1, single_ts2=excluded.single_ts2, timeout_ts1=excluded.timeout_ts1, timeout_ts2=excluded.timeout_ts2, 
                                        last_seen=excluded.last_seen''',
                                    (peer_id, master, peer_data.get("CALLSIGN"), peer_data.get("LOCATION"), peer_data.get("DESCRIPTION"),
                                    peer_data.get("IP"), peer_data.get("PORT"), peer_data.get("CONNECTED"), peer_data.get("SLOTS"),
                                    peer_data.get("TX_FREQ"), peer_data.get("RX_FREQ"),
                                    peer_data.get("PACKAGE_ID"), peer_data.get("SOFTWARE_ID"), peer_data.get("URL"), peer_data.get("COLORCODE"),
                                    peer_data.get("TX_POWER"), "{:.6f}".format(float(peer_data.get("LATITUDE").lstrip('+'))), 
                                    "{:.6f}".format(float(peer_data.get("LONGITUDE").lstrip('+'))), peer_data.get("HEIGHT"),
                                    peer_data.get("CONNECTION"), str(peer_data.get("TS1")), str(peer_data.get("TS2")), ", ".join(peer_data.get("TS1_STATIC", [])),
                                    ", ".join(peer_data.get("TS2_STATIC", [])), str(peer_data.get("SINGLE_TS1", {}).get("TGID")), str(peer_data.get("SINGLE_TS2", {}).get("TGID")), 
                                    str(peer_data.get("SINGLE_TS1", {}).get("TO")), str(peer_data.get("SINGLE_TS2", {}).get("TO")), now))

                #Insert or Update Peers Table
                for peer, peer_data in ctable["PEERS"].items():
                    txn.execute('''INSERT INTO peers_table
                                    (peer_name, callsign, location, description, master_ip, master_port, connection_status,
                                    connected, pings_sent, pings_ackd, slots, ts1, ts2, last_seen)
                                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                                    ON CONFLICT(peer_name) DO UPDATE SET
                                    callsign=excluded.callsign, location=excluded.location, description=excluded.description,
                                    master_ip=excluded.master_ip, master_port=excluded.master_port, connection_status=excluded.connection_status,
                                    connected=excluded.connected, pings_sent=excluded.pings_sent, pings_ackd=excluded.pings_ackd,
                                    slots=excluded.slots, ts1=excluded.ts1, ts2=excluded.ts2, last_seen=excluded.last_seen''',
                                (peer, peer_data.get("CALLSIGN"), peer_data.get("LOCATION"), peer_data.get("DESCRIPTION"),
                                peer_data.get("MASTER_IP"), peer_data.get("MASTER_PORT"), peer_data["STATS"].get("CONNECTION"),
                                peer_data["STATS"].get("CONNECTED"), peer_data["STATS"].get("PINGS_SENT"),
                                peer_data["STATS"].get("PINGS_ACKD"), peer_data.get("SLOTS"),
                                str(peer_data.get("TS1")), str(peer_data.get("TS2")), now))

                # Insert or Update OpenBridges Table
                for bridge, bridge_data in ctable["OPENBRIDGES"].items():
                    for stream_id, stream_data in bridge_data["STREAMS"].items():
                        txn.execute('''INSERT INTO openbridges_table
                                        (network_id, bridge_name, target_ip, target_port, last_seen)
                                        VALUES (?, ?, ?, ?, ?)
                                        ON CONFLICT(network_id) DO UPDATE SET
                                        bridge_name=excluded.bridge_name, target_ip=excluded.target_ip, last_seen=excluded.last_seen''',
                                    (bridge_data.get("NETWORK_ID"), bridge, bridge_data.get("TARGET_IP"), bridge_data.get("TARGET_PORT"), now))

            yield self.db.runInteraction(insert_data)
            logger.debug("CTABLE data exported to database successfully.")

        except Exception as err:
            logger.error(f"CTABLE export to database error: {err}")


    @inlineCallbacks
    def clean_old_entries(self):
        try:
            time_ago = datetime.now() - timedelta(minutes=2)
            def cleanup(txn):
                txn.execute("DELETE FROM masters_table WHERE last_seen < ?", (time_ago,))
                txn.execute("DELETE FROM peers_table WHERE last_seen < ?", (time_ago,))
                txn.execute("DELETE FROM openbridges_table WHERE last_seen < ?", (time_ago,))
            yield self.db.runInteraction(cleanup)
            logger.debug("CTABLE old entries cleaned from database.")
        except Exception as err:
            logger.error(f"clean_old_entries error: {err}")


    @inlineCallbacks
    def create_tables(self):
        try:
            def create_tbl(txn):
                txn.execute(''' CREATE TABLE IF NOT EXISTS Clients(
                            int_id INT UNIQUE PRIMARY KEY NOT NULL,
                            dmr_id TINYBLOB NOT NULL,
                            callsign VARCHAR(10) NOT NULL,
                            host VARCHAR(15),
                            options VARCHAR(300),
                            opt_rcvd TINYINT(1) DEFAULT False NOT NULL,
                            mode TINYINT(1) DEFAULT 4 NOT NULL,
                            logged_in TINYINT(1) DEFAULT False NOT NULL,
                            modified TINYINT(1) DEFAULT False NOT NULL,
                            psswd BLOB(256),
                            last_seen INT NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS talkgroup_ids (
                            id INT PRIMARY KEY UNIQUE NOT NULL, 
                            callsign VARCHAR(255) NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS subscriber_ids (
                            id INT PRIMARY KEY UNIQUE NOT NULL,
                            callsign VARCHAR(255) NOT NULL,
                            name VARCHAR(255) NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS peer_ids (
                            id INT PRIMARY KEY UNIQUE NOT NULL,
                            callsign VARCHAR(255) NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS last_heard (
                            date_time TEXT NOT NULL,
                            qso_time DECIMAL(3,2),
                            qso_type VARCHAR(20) NOT NULL,
                            system VARCHAR(50) NOT NULL,
                            tg_num INT NOT NULL,
                            dmr_id INT PRIMARY KEY UNIQUE NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS lstheard_log (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            date_time TEXT NOT NULL,
                            qso_time DECIMAL(3,2),
                            qso_type VARCHAR(20) NOT NULL,
                            system VARCHAR(50) NOT NULL,
                            tg_num INT NOT NULL,
                            dmr_id INT NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS tg_count (
                            date TEXT NOT NULL,
                            tg_num INT PRIMARY KEY NOT NULL,
                            qso_count INT NOT NULL,
                            qso_time DECIMAL(4,2) NOT NULL)''')

                txn.execute('''CREATE TABLE IF NOT EXISTS user_count (
                            date TEXT NOT NULL,
                            tg_num INT NOT NULL,
                            dmr_id INT NOT NULL,
                            qso_time DECIMAL(4,2) NOT NULL,
                            UNIQUE(tg_num, dmr_id))''')

            yield self.db.runInteraction(create_tbl)
            logger.info("Tables created successfully.")

        except Exception as err:
            logger.error(f"create_tables: {err}.")

    @inlineCallbacks
    def populate_tbl(self, table, lst_data, wipe_tbl, _file):
        try:
            def populate(txn, wipe_tbl):
                if table == "talkgroup_ids":
                    stm = "INSERT OR IGNORE INTO talkgroup_ids VALUES (?, ?)"
                    w_stm = "DELETE FROM talkgroup_ids"
                elif table == "subscriber_ids":
                    stm = stm = "INSERT OR IGNORE INTO subscriber_ids VALUES (?, ?, ?)"
                    w_stm = "DELETE FROM subscriber_ids"
                elif table == "peer_ids":
                    stm = "INSERT OR IGNORE INTO peer_ids VALUES (?, ?)"
                    w_stm = "DELETE FROM peer_ids"

                if wipe_tbl:
                    txn.execute(w_stm)

                result = txn.executemany(stm, lst_data).rowcount
                if result > 0:
                    logger.info(f"{result} entries added to: {table} table from: {_file}")

            yield self.db.runInteraction(populate, wipe_tbl)

        except Exception as err:
            logger.error(f"populate_tbl: {err}.")

    @inlineCallbacks
    def table_count(self, _table):
        try:
            if _table == "talkgroup_ids":
                stm = "SELECT count(*) FROM talkgroup_ids"
            elif _table == "subscriber_ids":
                stm = "SELECT count(*) FROM subscriber_ids"
            elif _table == "peer_ids":
                stm = "SELECT count(*) FROM peer_ids"

            result = yield self.db.runQuery(stm)
            if result:
                returnValue(result[0][0])
            else:
                returnValue(None)

        except Exception as err:
            logger.error(f"table_count: {err}.")

    @inlineCallbacks
    def ins_lstheard(self, qso_time, qso_type, system, tg_num, dmr_id):
        try:
            yield self.db.runOperation(
                "INSERT OR REPLACE INTO last_heard VALUES (datetime('now', 'localtime'), ?, ?, ?, ?, ?)",
                (qso_time, qso_type, system, tg_num, dmr_id))

        except Exception as err:
            logger.error(f"ins_lstheard: {err}.")

    @inlineCallbacks
    def ins_lstheard_log(self, qso_time, qso_type, system, tg_num, dmr_id):
        try:
            yield self.db.runOperation(
                '''INSERT INTO lstheard_log (date_time, qso_time, qso_type, system, tg_num, dmr_id)
                VALUES(datetime('now', 'localtime'), ?, ?, ?, ?, ?)''',
                (qso_time, qso_type, system, tg_num, dmr_id))

        except Exception as err:
            logger.error(f"ins_lstheard_log: {err}.")

    @inlineCallbacks
    def slct_2dict(self, _id, _table):
        try:
            if _table == "subscriber_ids":
                stm = "SELECT * FROM subscriber_ids WHERE id = ?"
            elif _table == "talkgroup_ids":
                stm = "SELECT * FROM talkgroup_ids WHERE id = ?"

            result = yield self.db.runQuery(stm, (_id,))
            if result:
                returnValue(result[0])
            else:
                returnValue(None)

        except Exception as err:
            logger.error(f"slct_2dict: {err}.")

    @inlineCallbacks
    def slct_2render(self, _table, _row_num):
        try:
            if _table == "last_heard":
                stm = '''SELECT date_time, qso_time, qso_type, system, tg_num,
                    (SELECT callsign FROM talkgroup_ids WHERE id = tg_num), dmr_id,
                    (SELECT json_array(callsign, name) FROM subscriber_ids WHERE id = dmr_id)
                    FROM last_heard ORDER BY date_time DESC LIMIT ?'''

            elif _table == "lstheard_log":
                stm = '''SELECT date_time, qso_time, qso_type, system, tg_num,
                    (SELECT callsign FROM talkgroup_ids WHERE id = tg_num), dmr_id,
                    (SELECT json_array(callsign, name) FROM subscriber_ids WHERE id = dmr_id)
                    FROM lstheard_log ORDER BY date_time DESC LIMIT ?'''

            result = yield self.db.runQuery(stm, (_row_num,))
            tmp_lst = []
            if result:
                for row in result:
                    if row[7]:
                        r_lst = list(row)
                        r_lst[7] = jloads(row[7])
                        tmp_lst.append(tuple(r_lst))
                    else:
                        tmp_lst.append(row)
            returnValue(tmp_lst)
        except Exception as err:
            logger.error(f"slct_2render: {err}.")

    @inlineCallbacks
    def clean_table(self, _table, _row_num):
        try:
            if _table == "last_heard":
                stm = '''DELETE FROM last_heard WHERE dmr_id NOT IN
                    (SELECT dmr_id FROM last_heard ORDER BY date_time DESC LIMIT ?)'''

            elif _table == "lstheard_log":
                stm = '''DELETE FROM lstheard_log WHERE id NOT IN
                    (SELECT id FROM lstheard_log ORDER BY date_time DESC LIMIT ?)'''

            yield self.db.runOperation(stm, (int(_row_num * 1.25),))
            logger.info(f"{_table} DB table cleaned successfully.")

        except Exception as err:
            logger.error(f"clean_tables: {err}.")

    @inlineCallbacks
    def ins_tgcount(self, _tg_num, _dmr_id, _qso_time):
        try:
            def db_actn(txn):
                txn.execute('''INSERT INTO tg_count VALUES (date('now', 'localtime'), ?, 1, ?)
                            ON CONFLICT (tg_num) DO UPDATE SET qso_time = qso_time + ?,
                            qso_count = qso_count + 1''', (_tg_num, _qso_time, _qso_time))

                txn.execute('''INSERT INTO user_count VALUES(date('now', 'localtime'), ?, ?, ?)
                            ON CONFLICT (tg_num, dmr_id) DO UPDATE SET qso_time = qso_time + ?''',
                            (_tg_num, _dmr_id, _qso_time, _qso_time))

            yield self.db.runInteraction(db_actn)

        except Exception as err:
            logger.error(f"ins_tgcount: {err}.")

    @inlineCallbacks
    def slct_tgcount(self, _row_num):
        try:
            rows = yield self.db.runQuery(
                '''SELECT tg_num, ifnull(callsign, ''), qso_count, qso_time FROM tg_count
                LEFT JOIN talkgroup_ids ON talkgroup_ids.id = tg_count.tg_num ORDER BY qso_time
                DESC LIMIT ?''', (_row_num,))
            if rows:
                res_lst = []
                for tg_num, name, qso_c, qso_time in rows:
                    res = yield self.db.runQuery(
                        '''SELECT ifnull(callsign, "N0CALL") FROM user_count 
                        LEFT JOIN subscriber_ids ON subscriber_ids.id = user_count.dmr_id
                        WHERE tg_num = ? ORDER BY qso_time DESC LIMIT 4''', (tg_num,))

                    res_lst.append((tg_num, name, qso_c, sec_time(qso_time), tuple([ite[0] for ite in res])))
                returnValue(res_lst)
            else:
                returnValue(None)

        except Exception as err:
            logger.error(f"slct_tgcount: {err}.")

    @inlineCallbacks
    def clean_tgcount(self):
        try:
            yield self.db.runOperation(
                "DELETE FROM tg_count WHERE date IS NOT date('now', 'localtime')")
            yield self.db.runOperation(
                "DELETE FROM user_count WHERE date IS NOT date('now', 'localtime')")

            logger.info("TG Count tables cleaned successfully")

        except Exception as err:
            logger.error(f"clean_tgcount: {err}.")


if __name__ == '__main__':
    from twisted.internet import reactor

    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s %(levelname)s %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    # Create an instance of MoniDB
    test_db = DashDB("html/db/dashboard.db")

    # Create tables
    test_db.create_tables()

    reactor.callLater(7, reactor.stop)
    reactor.run()
