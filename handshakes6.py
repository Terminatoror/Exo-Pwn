import os
import time
import threading
import logging
import subprocess
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
    __description__ = 'Displays the number of handshake files in the UI, updating every 10 seconds unless the service is not running.'

    def __init__(self):
        self.counter = None
        self.handshake_count = 0
        self.update_interval = 10
        self.update_thread = None
        self.running = False
        self.lock = threading.Lock()
        self.last_service_status = None

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
        ui.add_element('Head6', LabeledValue(color=BLACK, label='Head 6: ', value=str(self.handshake_count),
                position=(ui.width() / 2, ui.height() - 46),
                label_font=fonts.Bold, text_font=fonts.Medium))

    def on_ui_update(self, ui):
        # Check if secondary_pwn.service is running
        if self.is_service_running('second_pwn5.service'):
            ui.set('Head6', str(self.handshake_count))
        else:
            ui.set('Head6', 'X')

    def periodic_update(self):
        while self.running:
            self.update_counter()
            current_service_status = self.is_service_running('second_pwn5.service')

            if current_service_status != self.last_service_status:
                self.last_service_status = current_service_status
                self.trigger_ui_update()

            time.sleep(self.update_interval)

    def update_counter(self):
        handshake_dir = '/handshakes6/handshakes/'
        try:
            count = len([
                f for f in os.listdir(handshake_dir)
                if os.path.isfile(os.path.join(handshake_dir, f))
            ])
            with self.lock:
                self.handshake_count = count
            logging.info(f"Updated handshake count: {self.handshake_count}")
        except Exception as e:
            with self.lock:
                self.handshake_count = 0
            logging.error(f"Error counting handshake files: {e}")

    def is_service_running(self, service_name):
        try:
            result = subprocess.run(
                ['systemctl', 'is-active', service_name],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            if result.stdout.strip() == 'active':
                return True
            else:
                return False
        except Exception as e:
            logging.error(f"Error checking service status: {e}")
            return False

    def trigger_ui_update(self):
        from pwnagotchi.ui import ui
        self.on_ui_update(ui)
