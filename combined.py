import os
import time
import threading
import logging
import pwnagotchi
from pwnagotchi import plugins
import pwnagotchi.agent
import pwnagotchi.plugins as plugins
import pwnagotchi.ui.fonts as fonts
from pwnagotchi.ui.components import LabeledValue
from pwnagotchi.ui.view import BLACK


class HandshakeCounter(plugins.Plugin):
    __author__ = 'Terminatoror'
    __version__ = '1.1.0'
    __license__ = 'GPL3'
    __description__ = 'Displays the total number of handshake files from multiple directories in the UI, updating every 10 seconds.'

    def __init__(self):
        self.counter = None
        self.handshake_count = 0
        self.update_interval = 10
        self.update_thread = None
        self.running = False
        self.lock = threading.Lock()

    def on_loaded(self):
        logging.info("HandshakeCounter plugin loaded.")
        self.running = True
        self.update_thread = threading.Thread(target=self.periodic_update)
        self.update_thread.start()

    def on_unloaded(self):
        logging.info("HandshakeCounter plugin unloaded.")
        self.running = False

    def on_ui_setup(self, ui):
        logging.info("Setting up UI elements for HandshakeCounter.")
        ui.add_element('Total', LabeledValue(color=BLACK, label='Total: ', value=str(self.handshake_count),
                                             position=(ui.width() / 2, ui.height() - 46),
                                             label_font=fonts.Bold, text_font=fonts.Medium))

    def on_ui_update(self, ui):
        ui.set('Total', str(self.handshake_count))

    def periodic_update(self):
        while self.running:
            self.update_counter()
            time.sleep(self.update_interval)

    def update_counter(self):
        handshake_dirs = [
            '/handshakes2/handshakes/',
            '/handshakes3/handshakes/',
            '/handshakes4/handshakes/',
            '/handshakes5/handshakes/',
            '/handshakes6/handshakes/',
            '/handshakes/' 
        ]
        total_count = 0

        for handshake_dir in handshake_dirs:
            try:
                count = len([
                    f for f in os.listdir(handshake_dir)
                    if os.path.isfile(os.path.join(handshake_dir, f))
                ])
                total_count += count
            except Exception as e:
                logging.error(f"Error counting handshake files in {handshake_dir}: {e}")

        with self.lock:
            self.handshake_count = total_count

        logging.info(f"Updated total handshake count: {self.handshake_count}")
