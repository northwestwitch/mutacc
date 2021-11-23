###########
# BUILDER #
###########
FROM python:3.7.3-slim-stretch as builder
ENV PATH="/venv/bin:$PATH"

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install -y --no-install-recommends gcc libc-dev libz-dev

# Install virtualenv
RUN pip install virtualenv
RUN virtualenv --seeder pip /venv

ENV picard_version 2.26.5
ADD https://github.com/broadinstitute/picard/releases/download/${picard_version}/picard.jar /libs/

WORKDIR /app

# Install Mutacc dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


#########
# FINAL #
#########

FROM python:3.7.3-slim-stretch as deployer

LABEL about.home="https://github.com/Clinical-Genomics/mutacc"
LABEL about.documentation="https://github.com/Clinical-Genomics/mutacc/blob/master/docs/demo.md"
LABEL about.license="MIT License (MIT)"

RUN mkdir -p /usr/share/man/man1 && \
 		apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install -y --no-install-recommends openjdk-8-jre

# Create a non-root user to run commands
RUN groupadd --gid 10001 worker && useradd -g worker --uid 10001 --create-home worker

WORKDIR /home/worker/app
COPY . /home/worker/app

# Copy virtual environment from builder
ENV PATH="/venv/bin:$PATH"
COPY --chown=worker:worker --from=builder /venv /venv
COPY --chown=worker:worker --from=builder /libs /home/worker/libs

RUN echo export PATH="/venv/bin:\$PATH" > /etc/profile.d/venv.sh

# Install the app
RUN pip install --no-cache-dir .

USER worker
