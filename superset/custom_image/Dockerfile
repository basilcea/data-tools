ARG SUPERSET_VERSION=3.0.1
FROM apache/superset:${SUPERSET_VERSION}
ARG TARGETARCH

USER root

# copy custom scripts
RUN mkdir /app/pythonpath/keycloak && chmod 755 /app/pythonpath/keycloak

# Install chrome webdriver
# See:
#   - https://github.com/apache/superset/blob/4fa3b6c7185629b87c27fc2c0e5435d458f7b73d/docs/src/pages/docs/installation/email_reports.mdx
#   - https://chromedriver.chromium.org/downloads/version-selection
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | tee /etc/apt/trusted.gpg.d/google-chrome.asc \
  && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends google-chrome-stable git unzip jq \
  && curl -sL https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json -o chromedrivers.json \
  && curl -sLO $(jq -j '.channels.Stable.downloads.chromedriver | map(select(.platform == "linux64")) | .[0].url' chromedrivers.json) \
  && unzip chromedriver-linux64.zip \
  && chmod +x chromedriver-linux64/chromedriver \
  && mv chromedriver-linux64/chromedriver /usr/bin \
  && apt-get remove -yqq jq \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* chromedriver-linux64/ \
  && rm -f google-chrome-stable_current_amd64.deb chromedriver-linux64.zip chromedrivers.json \
  && google-chrome --version \
  && chromedriver --version \
  && mkdir -p /opt/oaf-tests

COPY test/*.py /opt/oaf-tests/

# Install python dependencies
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir \
  authlib \
  'cryptography<40,>=39.0.1' \
  elasticsearch-dbapi \
  flask_openid \
  flower \
  gevent \
  # FIXME: Revert back to the flask-oidc pip package above when the PR
  # being tracked is merged or find an alternative to flask-oidc
  "git+https://github.com/puiterwijk/flask-oidc.git@refs/pull/144/head" \
  'holidays<0.24,>=0.23' \
  mysqlclient \
  psycopg2 \
  prophet \
  pybigquery \
  PyJWT \
  pymssql \
  redis \
  requests-cache \
  shillelagh \
  'snowflake-connector-python==3.4.0' \
  snowflake-sqlalchemy \
  trino \
  'trino[sqlalchemy]'

# chrome only runs on amd64 arch, so only run the test if we can
# hadolint ignore=DL3059
RUN if [ "$TARGETARCH" == "amd64" ]; then python -m unittest discover -s /opt/oaf-tests; fi

USER superset
