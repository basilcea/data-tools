# WARNING: this python file will be evaluated as a Helm template at deployment time
# Watch out for the template placeholders, which may break python syntax

import ast
import re
from urllib.parse import quote

from celery.schedules import crontab

from superset.utils.machine_auth import MachineAuthProvider
from superset.utils.urls import headless_url
from superset.security import SupersetSecurityManager

from flask import redirect, request
from flask_oidc import OpenIDConnect
from flask_login import login_user
from flask_appbuilder.security.manager import AUTH_OID
from flask_appbuilder.security.views import AuthOIDView
from flask_appbuilder.views import expose

# See https://github.com/apache/superset/blob/master/RESOURCES/FEATURE_FLAGS.md for full list
FEATURE_FLAGS = {
    "ALERT_REPORTS": True,
    "THUMBNAILS": True,
}
for f in [f.strip() for f in os.getenv("FEATURE_FLAGS", "").split(",")]:
    FEATURE_FLAGS[f] = True

DOCUMENTATION_URL = (
    "https://oneacrefund.atlassian.net/wiki/spaces/OAFDEV/pages/1117978661/Superset"
)
DOCUMENTATION_TEXT = "Documentation"
DOCUMENTATION_ICON = "fa-question"
EMAIL_NOTIFICATIONS = ast.literal_eval(os.getenv("EMAIL_NOTIFICATIONS", "True"))
SMTP_HOST = os.getenv("SMTP_HOST", "localhost")
SMTP_STARTTLS = ast.literal_eval(os.getenv("SMTP_STARTTLS", "True"))
SMTP_SSL = ast.literal_eval(os.getenv("SMTP_SSL", "False"))
SMTP_USER = os.getenv("SMTP_USER", "superset")
SMTP_PORT = os.getenv("SMTP_PORT", 25)
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "superset")
SMTP_MAIL_FROM = os.getenv("SMTP_MAIL_FROM", "superset@superset.com")
SLACK_API_TOKEN = os.getenv("SLACK_API_TOKEN", None)
LANGUAGES = {
    "en": {"flag": "us", "name": "English"},
    "fr": {"flag": "fr", "name": "French"},
}
WTF_CSRF_ENABLED = False
SUPERSET_WEBSERVER_TIMEOUT = 120
SECRET_KEY = os.getenv("SECRET_KEY", None)
# Upgrade from superset 1.4.0 to 1.4.1 requires migration of the
# secret key for installations that were using the default secret
# key as set below
PREVIOUS_SECRET_KEY = os.getenv("PREVIOUS_SECRET_KEY", "thisismyscretkey")

GLOBAL_ASYNC_QUERIES_JWT_SECRET = os.getenv(
    "JWT_SECRET", "someLongStringMoreThan32charsIfPossible"
)
GLOBAL_ASYNC_QUERIES_REDIS_CONFIG = {
    "port": env("REDIS_PORT"),
    "host": env("REDIS_HOST"),
    "db": 0,
    "ssl": False,
}

# This is the maximum amount of time allowed for queries in SQL lab
SQLLAB_ASYNC_TIME_LIMIT_SEC = int(os.getenv("MAX_QUERY_EXECUTION_TIME", 60))


class AuthOIDCView(AuthOIDView):
    @expose("/login/", methods=["GET", "POST"])
    def login(self):
        security_manager = self.appbuilder.sm
        oidc = security_manager.oid

        @self.appbuilder.sm.oid.require_login
        def handle_login():
            user = security_manager.auth_user_oid(oidc.user_getfield("email"))

            if user is None:
                info = oidc.user_getinfo(
                    ["preferred_username", "given_name", "family_name", "email"]
                )
                role = os.getenv("DEFAULT_ROLE", "Alpha")

                user = security_manager.add_user(
                    info.get("preferred_username"),
                    info.get("given_name"),
                    info.get("family_name"),
                    info.get("email"),
                    security_manager.find_role(role),
                )
            login_user(user, remember=False)
            return redirect(self.appbuilder.get_url_for_index)

        return handle_login()

    @expose("/logout/", methods=["GET", "POST"])
    def logout(self):
        oidc = self.appbuilder.sm.oid
        oidc.logout()
        super(AuthOIDCView, self).logout()
        redirect_url = request.url_root.strip("/") + self.appbuilder.get_url_for_login

        return redirect(
            oidc.client_secrets.get("issuer")
            + "/protocol/openid-connect/logout?redirect_uri="
            + quote(redirect_url)
        )


class OIDCSecurityManager(SupersetSecurityManager):
    def __init__(self, appbuilder):
        super(OIDCSecurityManager, self).__init__(appbuilder)
        if self.auth_type == AUTH_OID:
            self.oid = OpenIDConnect(self.appbuilder.get_app)
        self.authoidview = AuthOIDCView


AUTH_TYPE = AUTH_OID
OIDC_CLIENT_SECRETS = "/app/pythonpath/keycloak_client_secrets.json"
OIDC_ID_TOKEN_COOKIE_SECURE = False
OIDC_REQUIRE_VERIFIED_EMAIL = False
OIDC_RESOURCE_SERVER_ONLY = False
# pylint: disable-next=invalid-name
CUSTOM_SECURITY_MANAGER = OIDCSecurityManager
AUTH_USER_REGISTRATION = True


class CeleryConfig:
    broker_url = f"redis://{env('REDIS_HOST')}:{env('REDIS_PORT')}/0"
    result_backend = f"redis://{env('REDIS_HOST')}:{env('REDIS_PORT')}/0"
    imports = ("superset.sql_lab", "superset.tasks", "superset.tasks.thumbnails")
    worker_log_level = "INFO"
    # NOTE: worker_prefetch_multiplier is number of tasks reserved per thread of each
    # worker. If some thread is taking a long time then everything queued on
    # that worker will be blocked until the task is completed even if there are
    # other threads that free (see: https://docs.celeryq.dev/en/stable/userguide/optimizing.html#prefetch-limits)
    worker_prefetch_multiplier = int(os.getenv("MAX_QUEUED_QUERIES_PER_THREAD", 1))
    task_soft_time_limit = SQLLAB_ASYNC_TIME_LIMIT_SEC + 30
    task_time_limit = SQLLAB_ASYNC_TIME_LIMIT_SEC + 40
    worker_concurrency = int(os.getenv("MAX_QUERIES_PER_WORKER", 10))
    task_acks_late = True
    task_annotations = {
        "sql_lab.get_sql_results": {
            "rate_limit": "100/s",
        },
        "email_reports.send": {
            "rate_limit": "1/s",
            "time_limit": 600,
            "soft_time_limit": 600,
            "ignore_result": True,
        },
        "tasks.add": {"rate_limit": "10/s"},
    }
    beat_schedule = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(minute=0, hour=0),
        },
        "cache-warmup-hourly": {
            "task": "cache-warmup",
            "schedule": crontab(minute="*/30", hour="*"),
            "kwargs": {
                "strategy_name": "top_n_dashboards",
                "top_n": 10,
                "since": "7 days ago",
            },
        },
    }


# pylint: disable-next=invalid-name
CELERY_CONFIG = CeleryConfig

# Override webdriver login flow, as the default is not working with OIDC enabled
# See https://github.com/apache/superset/issues/14330#issuecomment-885656343


def auth_driver(driver, user):
    # Setting cookies requires doing a request first,
    # but /login is redirected to oauth provider, so we use a dummy URI
    driver.get(headless_url("/doesnotexist"))

    cookies = MachineAuthProvider.get_auth_cookies(user)

    for cookie_name, cookie_val in cookies.items():
        driver.add_cookie(dict(name=cookie_name, value=cookie_val))

    return driver


WEBDRIVER_AUTH_FUNC = auth_driver
EMAIL_PAGE_RENDER_WAIT = 120
SCREENSHOT_LOCATE_WAIT = 100
SCREENSHOT_LOAD_WAIT = 600
THUMBNAIL_SELENIUM_USER = "admin"
WEBDRIVER_BASEURL = (
    'http://{{ template "superset.fullname" . }}:{{ .Values.service.port }}/'
)
WEBDRIVER_BASEURL_USER_FRIENDLY = os.getenv("BASE_URL", "https://data.oneacrefund.org")
# Target address for cache calls
SUPERSET_WEBSERVER_ADDRESS = '{{ template "superset.fullname" . }}'
WEBDRIVER_TYPE = "chrome"
WEBDRIVER_OPTION_ARGS = [
    "--force-device-scale-factor=2.0",
    "--high-dpi-support=2.0",
    "--headless",
    "--disable-gpu",
    "--disable-dev-shm-usage",
    "--no-sandbox",
    "--disable-setuid-sandbox",
    "--disable-extensions",
    "--disable-crash-reporter",
]

REDIS_URL = f"redis://{env('REDIS_HOST')}:{env('REDIS_PORT')}/0"
THUMBNAIL_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 7 * 86400,
    "CACHE_KEY_PREFIX": "thumbnail_",
    "CACHE_NO_NULL_WARNING": True,
    "CACHE_REDIS_URL": REDIS_URL,
}
DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 86400,
    "CACHE_KEY_PREFIX": "superset_results_",
    "CACHE_REDIS_URL": REDIS_URL,
}
CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 86400,
    "CACHE_KEY_PREFIX": "metadata_",
    "CACHE_REDIS_URL": REDIS_URL,
}
EXPLORE_FORM_DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 86400,
    "CACHE_KEY_PREFIX": "explore_",
    "CACHE_REDIS_URL": REDIS_URL,
}
FILTER_STATE_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 86400,
    "CACHE_KEY_PREFIX": "filter_",
    "CACHE_REDIS_URL": REDIS_URL,
}

# See https://github.com/apache/superset/blob/master/CONTRIBUTING.md#async-chart-queries
GLOBAL_ASYNC_QUERIES_TRANSPORT = os.getenv("GLOBAL_ASYNC_QUERIES_TRANSPORT", "polling")
GLOBAL_ASYNC_QUERIES_WEBSOCKET_URL = f"{re.sub('^http','ws',env('BASE_URL'))}/ws"

SQLALCHEMY_ENGINE_OPTIONS = {
    # Raise these numbers when we start running out of database connections.
    # See:
    #   - http://sqlalche.me/e/13/3o7r
    #   - https://github.com/apache/superset/issues/8207#issuecomment-530056051
    "pool_size": int(os.getenv("SQLALCHEMY_POOL_SIZE", "30")),
    "max_overflow": int(os.getenv("SQLALCHEMY_MAX_OVERFLOW", "15")),
}

RATELIMIT_STORAGE_URI = REDIS_URL

TALISMAN_CONFIG = {
    "force_https": False,  # Handled upstream at ingress... Enabling this could break reports.
    "content_security_policy": {
        "default-src": "'self' mapbox.com *.mapbox.com",
        "object-src": "'none'",
        "style-src": "'self' 'unsafe-inline'",
        "img-src": "'self' blob:",
        # User/Role management pages have <a href="javascript:void(0)"...> which
        # are blocked by CSP. Loosen this restriction until Superset has these
        # offending hrefs removed.
        "script-src": "'self' 'unsafe-inline' blob:",
    },
}
