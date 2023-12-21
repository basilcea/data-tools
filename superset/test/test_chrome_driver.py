import unittest
from selenium import webdriver


class TestChromeDriver(unittest.TestCase):
    def setUp(self):
        options = webdriver.chrome.options.Options()
        options.add_argument("--headless")
        options.add_argument("--remote-debugging-port=9222")
        # Chrome does not support sandboxing in docker environments
        # See https://stackoverflow.com/a/59154049
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-crash-reporter")

        self.driver = webdriver.Chrome("/usr/bin/chromedriver", options=options)

    def tearDown(self):
        self.driver.quit()

    def test_driver_supports_installed_chrome(self):
        # Throws if driver and chrome are mismatched
        self.driver.get("http://www.google.com/")
